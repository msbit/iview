#!/bin/bash
#
# iView Downloader for Linux/OSX
# v7.0

#
# This first part defines some of the most commonly changed variables in this script
#

# Uncomment the flvstremer you wish to use (ONLY CHOOSE ONE)

# Time to wait between retrys (uses the linux sleep command)
SLEEPTIME=5s

# Number of times to retry before moving on to the next download in the list
MAXRETRIES=5

#####################
# Don't edit below here unless you know what you are doing

#These are the SWF hash and size
SWFPARAMS='-w 96cc76f1d5385fb5cda6e2ce5c73323a399043d0bb6c687edd807e5c73c42b37 -x 2122'

#Directories we will use to store stuff
CURDIR=$(dirname "${0}")
FFMPEG='ffmpeg'
FLVSTREAMER='rtmpdump_universal'

TEMPDIR=$(mktemp -d -t iview)
TEMPINDEX=${TEMPDIR}/index
TEMPINDEXGZ=${TEMPDIR}/index.gz

function searchShows() {
  echo "Enter search string (not case sensitive):"
  read SEARCHSTRING
  
  cat ${TEMPDIR}/possibleshows.txt | grep -i ${SEARCHSTRING} > ${TEMPDIR}/rawsearchresults.txt
  nl ${TEMPDIR}/rawsearchresults.txt | sed 's/ *//' > ${TEMPDIR}/searchresults.txt
  cat ${TEMPDIR}/searchresults.txt | sed 's/\(.*\) .*/\1/'

  LINES=$(cat ${TEMPDIR}/searchresults.txt | wc -l | sed 's/ //g')
  case ${LINES} in
    0)
      echo "No matching results found"
      read -p "Press enter to continue..."
      return
      ;;
    *)
      ;;
  esac

  echo "Select a number to add a show to download list, 'a' adds all, 0 adds nothing:"
  read NUMBER

  case ${NUMBER} in
    a|A)  # Adds all shows currently in list to the downloadlist
      cat ${TEMPDIR}/rawsearchresults.txt | sed 's/.* //' >> ${TEMPDIR}/download_list.txt
      ;;
    0)
      ;;  # Add nothing
    *)  # Add only the selected show to the download list
      SHOWPATH=$(grep -w ^"${NUMBER}" ${TEMPDIR}/searchresults.txt | sed "s/^${NUMBER}//g" | tr -d '\t')
      echo "${SHOWPATH}" >> ${TEMPDIR}/download_list.txt
      ;;
  esac
}

function downloadShowList() {
  # Erase old lists
  rm ${TEMPDIR}/possibleshows.txt
  rm ${TEMPINDEX}

  echo "Downloading Index..."

  # Download JSON index & ungzip if needed
  curl -q "http://tviview.abc.net.au/iview/api2/?keyword=0-9" > ${TEMPINDEXGZ}
  gunzip ${TEMPINDEXGZ}
  mv ${TEMPINDEXGZ} ${TEMPINDEX}
  cat ${TEMPINDEX} > ${TEMPDIR}/showindex
  rm ${TEMPINDEX}

  curl -q "http://tviview.abc.net.au/iview/api2/?keyword=a-c" >> ${TEMPINDEXGZ}
  gunzip ${TEMPINDEXGZ}
  mv ${TEMPINDEXGZ} ${TEMPINDEX}
  cat ${TEMPINDEX} >> ${TEMPDIR}/showindex
  rm ${TEMPINDEX}

  curl -q "http://tviview.abc.net.au/iview/api2/?keyword=d-k" >> ${TEMPINDEXGZ}
  gunzip ${TEMPINDEXGZ}
  mv ${TEMPINDEXGZ} ${TEMPINDEX}
  cat ${TEMPINDEX} >> ${TEMPDIR}/showindex
  rm ${TEMPINDEX}

  curl -q "http://tviview.abc.net.au/iview/api2/?keyword=l-p" >> ${TEMPINDEXGZ}
  gunzip ${TEMPINDEXGZ}
  mv ${TEMPINDEXGZ} ${TEMPINDEX}
  cat ${TEMPINDEX} >> ${TEMPDIR}/showindex
  rm ${TEMPINDEX}

  curl -q "http://tviview.abc.net.au/iview/api2/?keyword=q-z" >> ${TEMPINDEXGZ}
  gunzip ${TEMPINDEXGZ}
  mv ${TEMPINDEXGZ} ${TEMPINDEX}
  cat ${TEMPINDEX} >> ${TEMPDIR}/showindex
  rm ${TEMPINDEX}
  
  echo "Reading Index..."

  #This will separate the lines out with either a series or a show descriptor on each line
cat ${TEMPDIR}/showindex | sed 's/{\"a\"\:\"/\
/g' > ${TEMPDIR}/series.txt

  LINES=$(cat ${TEMPDIR}/series.txt | wc -l | sed 's/ //g')
  COUNTER=1
  while [ ${COUNTER} -lt ${LINES} ]; do
    let COUNTER=COUNTER+1

    # Get line and check ID number length
    CURRENT=$(sed "${COUNTER}!d" ${TEMPDIR}/series.txt)

    ID=$(echo "${CURRENT}" | sed 's/\".*//g')
    COUNT=$(echo ${ID} | wc -m)

    # If 7 chars then find showpath and add to list otherwise grab the series name for the next few shows (8 defines a series, 7 defines a show)
    if [ ${COUNT} = "7" ]; then
      #                           Remove ID num                  Remove any \    Remove junk at end so last item is show path
      CURRENT=$(echo "${CURRENT}" | sed 's/[0-9]*\"\,\"b\"\:\"//' | sed 's/\\//g' | sed 's/mp4.*/\mp4/' | sed 's/flv.*/flv/') 

      # Now we want to leave only the first and last items on the line
      SHOWNAME=$(echo "${CURRENT}" | sed 's/\".*//g' | sed 's,\/,-,g' | sed 's/\&amp\;/\&/')  # This also replaces / with - and replaces &amp; with &
      SHOWPATH=$(echo "${CURRENT}" | sed 's/.*\"//g')
      echo "${SERIESNAME} ${SHOWNAME} ${SHOWPATH}" >> ${TEMPDIR}/possibleshows.txt
    else
      CURRENT=$(echo "${CURRENT}" | sed 's/[0-9]*\"\,\"b\"\:\"//' | sed 's/\\//g' | sed 's/mp4.*/\mp4/' | sed 's/flv.*/flv/') 
      SERIESNAME=$(echo "${CURRENT}" | sed 's/\".*//g' | sed 's,\/,-,g' | sed 's/\&amp\;/\&/')   # This also replaces / with - and replaces &amp; with 
    fi
  done

  sort ${TEMPDIR}/possibleshows.txt > ${TEMPDIR}/temp.txt
  mv ${TEMPDIR}/temp.txt ${TEMPDIR}/possibleshows.txt
}

function getShow() {
  echo 
  echo "Which list do you wish to browse:"
  echo 
  echo "A. Download new list from iView server"
  echo
  echo "B. Use existing list"
  echo
  echo "C. Manually Enter"
  echo
  echo "Type the letter and press Enter:"
  read SELECTION

  echo 
  echo "You selected ${SELECTION}"

  MANUAL='false'

  case ${SELECTION} in
    a|A)
      downloadShowList
      ;;
    b|B)
      ;;
    c|C)
      echo "Enter showname (What you want the file to be saved as):"
      read SHOWNAME
      echo "Enter showpath (The server path):"
      read SHOWPATH
      echo "${SHOWNAME} ${SHOWPATH}" >> ${TEMPDIR}/download_list.txt
      MANUAL='true'
      ;;
    *)
      echo "Invalid Selection, Please pick again."
      MANUAL='true'
      ;;
  esac

  clear

  case ${MANUAL} in
    'false')
      cat ${TEMPDIR}/possibleshows.txt | nl | sed 's/ *//' > ${TEMPDIR}/filtered_shows.txt
      cat ${TEMPDIR}/filtered_shows.txt | sed 's/\(.*\) .*/\1/'

      echo "Select a number to add a show to download list, 'a' adds all,"
      echo "0 adds nothing, and 's' allows you to search this list:"
      read NUMBER

      case ${NUMBER} in
        a|A)  # Adds all shows currently in list to the downloadlist
          cat ${TEMPDIR}/possibleshows.txt >> ${TEMPDIR}/download_list.txt
          ;;
        s|S)
          searchShows
          ;;
        0)
          ;;
        *)  # Add only the selected show to the download list
          SHOWPATH=$(grep -w ^"${NUMBER}" ${TEMPDIR}/filtered_shows.txt | sed "s/^${NUMBER}//g" | tr -d '\t')
          echo "${SHOWPATH}" >> ${TEMPDIR}/download_list.txt
          ;;
      esac
      ;;
    *)
      ;;
  esac
}

function downloadShow() {
  FILENAME=$(echo ${1} | sed 's/\(.*\) .*/\1/')
  SHOWPATH=$(echo ${1} | sed 's/.* //')
  SHOWEXT=$(echo ${1} | sed 's/.*\.//g')

  RETRY=0
  SUCCESS='false'

  while [ ${MAXRETRIES} -gt ${RETRY} ]; do
    let RETRY=RETRY+1

    echo "Attempt ${RETRY} of ${MAXRETRIES}"
    echo "Retrieving Token..."
    curl -q http://tviview.abc.net.au/iview/auth/?v2 > ${TEMPDIR}/auth.xml
    TOKEN=$(cat ${TEMPDIR}/auth.xml | grep token | sed 's/.*<token>//g' | sed 's/\\&amp;/\\&/g' | sed 's,</token>.*,,g' | sed 's/ //g')
    HOST=$(cat ${TEMPDIR}/auth.xml | grep host | sed 's/<host>//g' | sed 's,</host>,,g' | sed 's/ //g' | tr -d '\r')

    #Generate the right server path
    case ${SHOWEXT} in
      "mp4")
        case ${HOST} in
          "Akamai")
            SERVERPATH=${SHOWPATH}.mp4
            ;;
          *)
            SERVERPATH=mp4:${SHOWPATH}
            ;;
        esac
        ;;
      *)
        SERVERPATH=${SHOWPATH}
        ;;
    esac

    echo "Ok, you will be requesting ${SERVERPATH}"
    echo "and saving the stream with the filename ${FILENAME}.${SHOWEXT}"
    echo "from ABC iView servers on ${HOST}"
    echo "using the auth ${TOKEN}"

    case ${HOST} in
      "Akamai")
        echo "Running Akamai..."
        ${FLVSTREAMER} --resume -r rtmp://cp53909.edgefcs.net////flash/playback/_definst_/${SERVERPATH} -t rtmp://cp53909.edgefcs.net/ondemand?auth=${TOKEN} -o "${CURDIR}"/"${FILENAME}.${SHOWEXT}" ${SWFPARAMS}
        ;;
      *)
        echo "Running Hostworks..."
        ${FLVSTREAMER} --resume -r "rtmp://203.18.195.10/ondemand?auth=${TOKEN}&${SERVERPATH}" -y ${SERVERPATH} -o "${CURDIR}"/"${FILENAME}.${SHOWEXT}" ${SWFPARAMS}
        ;;
    esac
    case ${?} in
      0)
        SUCCESS='true'
        ;;
      *)
        echo "Error code ${?}"
        echo "Sleeping for ${SLEEPTIME}"
        sleep ${SLEEPTIME}
        ;;
    esac

    # If we failed with one type then swap extentions for our next try
#   case ${SHOWEXT} in
#     "mp4")
#       SHOWEXT=flv
#       ;;
#     *)
#       SHOWEXT=mp4
#       ;;
#   esac
  done

  case ${SUCCESS} in
    'true') # Successful download
      echo ${1} >> ${TEMPDIR}/CompleteDownloads.txt
      ;;
    *) # Unsuccessful download
      echo ${1} >> ${TEMPDIR}/IncompleteDownloads.txt
      ;;
  esac
}

function runDownloadShow() {
  touch ${TEMPDIR}/CompleteDownloads.txt
  touch ${TEMPDIR}/IncompleteDownloads.txt
  LINES=$(cat ${TEMPDIR}/download_list.txt | wc -l | sed 's/ //g')
  echo "Number of downloads ${LINES}"

  COUNTER=0
  while [ ${COUNTER} -lt ${LINES} ]; do
    let COUNTER=COUNTER+1
    CURRENT=$(sed "${COUNTER}!d" ${TEMPDIR}/download_list.txt)
    downloadShow "${CURRENT}"
  done

  echo
  echo
  echo "Completed Downloads:"
  cat ${TEMPDIR}/CompleteDownloads.txt | sed 's/\(.*\) .*/\1/'

  echo
  echo
  echo "Incomplete Downloads:"
  cat ${TEMPDIR}/IncompleteDownloads.txt | sed 's/\(.*\) .*/\1/'

  mv ${TEMPDIR}/IncompleteDownloads.txt ${TEMPDIR}/download_list.txt

  read -p "Press enter to continue..."
}

function convertFiles() {
  LINES=$(cat ${TEMPDIR}/CompleteDownloads.txt | wc -l | sed 's/ //g')
  echo "Number of downloads ${LINES}"

  COUNTER=0
  while [ ${COUNTER} -lt ${LINES} ]; do
    let COUNTER=COUNTER+1
    CURRENT=$(sed "${COUNTER}!d" ${TEMPDIR}/CompleteDownloads.txt)

    FILENAME=$(echo ${1} | sed 's/\(.*\) .*/\1/')
    SHOWPATH=$(echo ${1} | sed 's/.* //')
    SHOWEXT=$(echo ${1} | sed 's/.*\.//g')

    ${FFMPEG} -i "${CURDIR}"/"${FILENAME}.${SHOWEXT}" -aspect 16:9 -acodec copy -vcodec copy "${CURDIR}"/FIXED_"${FILENAME}".avi
  done
  read -p "Press enter to continue..."
}

clear
echo "ABC iView Downloader by sge, converted to OSX by lightguard, updated by vipher"
echo "Version 7.0"
echo "This script simplifies the process of downloading streams off ABC iView."
echo 
echo "NOTE THIS CAREFULLY: THIS SCRIPT CAN BE UNRELIABLE."
echo "WHEN IF FAILS, TRY AGAIN, OR PICK ANOTHER SHOW."
echo 
echo "The creators provide no warranty for this script. It may stop working with no notice."

read -p "Press enter to continue..."

until [ 1 -lt 0 ]; do
  clear
  echo 
  echo "Please Select an Option"
  echo "1. Add another show to the download list"
  echo "2. View the download list"
  echo "3. Clear the download list"
  echo "4. Download the list (Attempts to retry ${MAXRETRIES} times)"
  echo "5. View the completed download list"
  echo "6. Convert all files in completed list"
  echo "7. Exit"
  read OPTION

  case ${OPTION} in
    1)
      getShow
      ;;
    2)
      echo 
      cat ${TEMPDIR}/download_list.txt
      read -p "Press enter to continue..."
      ;;
    3)
      rm ${TEMPDIR}/download_list.txt
      rm ${TEMPDIR}/CompleteDownloads.txt
      rm ${TEMPDIR}/IncompleteDownloads.txt
      ;;
    4)
      runDownloadShow
      ;;
    5)
      echo 
      cat ${TEMPDIR}/CompleteDownloads.txt
      read -p "Press enter to continue..."
      ;;
    6)
      convertFiles
      ;;
    7)
      exit
      ;;
  esac
done

#!/bin/bash

SLEEPTIME=5s
MAXRETRIES=5
SWFPARAMS='-w 96cc76f1d5385fb5cda6e2ce5c73323a399043d0bb6c687edd807e5c73c42b37 -x 2122'

CURDIR=$(dirname "${0}")
FFMPEG='ffmpeg'
FLVSTREAMER='rtmpdump_universal'

TEMPDIR=$(mktemp -d -t iview)
DOWNLOAD_LIST=${TEMPDIR}/download_list.txt
COMPLETE_DOWNLOADS=${TEMPDIR}/CompleteDownloads.txt
INCOMPLETE_DOWNLOADS=${TEMPDIR}/IncompleteDownloads.txt
SEARCH_RESULTS=${TEMPDIR}/searchresults.txt
RAWSEARCH_RESULTS=${TEMPDIR}/rawsearchresults.txt
POSSIBLE_SHOWS=${TEMPDIR}/possibleshows.txt
SERIES=${TEMPDIR}/series.txt
FILTERED_SHOWS=${TEMPDIR}/filtered_shows.txt
AUTH_XML=${TEMPDIR}/auth.xml
TEMP_TXT=${TEMPDIR}/temp.txt
SHOW_INDEX=${TEMPDIR}/showindex

function searchShows() {
  echo "Enter search string (not case sensitive):"
  read SEARCHSTRING
  
  cat ${POSSIBLE_SHOWS} | grep -i ${SEARCHSTRING} > ${RAWSEARCH_RESULTS}
  nl ${RAWSEARCH_RESULTS} | sed 's/ *//' > ${SEARCH_RESULTS}
  cat ${SEARCH_RESULTS} | sed 's/\(.*\) .*/\1/'

  LINES=$(cat ${SEARCH_RESULTS} | wc -l | sed 's/ //g')
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
    a|A)
      cat ${RAWSEARCH_RESULTS} | sed 's/.* //' >> ${DOWNLOAD_LIST}
      ;;
    0)
      ;;
    *)
      SHOWPATH=$(grep -w ^"${NUMBER}" ${SEARCH_RESULTS} | sed "s/^${NUMBER}//g" | tr -d '\t')
      echo "${SHOWPATH}" >> ${DOWNLOAD_LIST}
      ;;
  esac
}

function downloadShowList() {
  # Erase old lists
  rm ${POSSIBLE_SHOWS}
  TEMPINDEX=$(mktemp -t iview-temp-index)

  echo "Downloading Index..."

  for CATEGORY in "0-z"
  do
    curl -q "http://tviview.abc.net.au/iview/api2/?keyword=${CATEGORY}" >> ${TEMPINDEX}
    cat ${TEMPINDEX} >> ${SHOW_INDEX}
    rm ${TEMPINDEX}
  done

  echo "Reading Index..."

  #This will separate the lines out with either a series or a show descriptor on each line
  cat ${SHOW_INDEX} | sed 's/{\"a\"\:\"/\
/g' > ${SERIES}

  LINES=$(cat ${SERIES} | wc -l | sed 's/ //g')
  COUNTER=1
  while [ ${COUNTER} -lt ${LINES} ]; do
    let COUNTER=COUNTER+1

    CURRENT=$(sed "${COUNTER}!d" ${SERIES})
    ID=$(echo "${CURRENT}" | sed 's/\".*//g')
    COUNT=$(echo ${ID} | wc -m)

    # If 7 chars then find showpath and add to list otherwise grab the series name for the next few shows (8 defines a series, 7 defines a show)
    if [ ${COUNT} = "7" ]; then
      CURRENT=$(echo "${CURRENT}" | sed 's/[0-9]*\"\,\"b\"\:\"//' | sed 's/\\//g' | sed 's/mp4.*/\mp4/' | sed 's/flv.*/flv/') 

      SHOWNAME=$(echo "${CURRENT}" | sed 's/\".*//g' | sed 's,\/,-,g' | sed 's/\&amp\;/\&/')  # This also replaces / with - and replaces &amp; with &
      SHOWPATH=$(echo "${CURRENT}" | sed 's/.*\"//g')
      echo "${SERIESNAME} ${SHOWNAME} ${SHOWPATH}" >> ${POSSIBLE_SHOWS}
    else
      CURRENT=$(echo "${CURRENT}" | sed 's/[0-9]*\"\,\"b\"\:\"//' | sed 's/\\//g' | sed 's/mp4.*/\mp4/' | sed 's/flv.*/flv/') 
      SERIESNAME=$(echo "${CURRENT}" | sed 's/\".*//g' | sed 's,\/,-,g' | sed 's/\&amp\;/\&/')   # This also replaces / with - and replaces &amp; with 
    fi
  done

  sort ${POSSIBLE_SHOWS} > ${TEMP_TXT}
  mv ${TEMP_TXT} ${POSSIBLE_SHOWS}
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
      echo "${SHOWNAME} ${SHOWPATH}" >> ${DOWNLOAD_LIST}
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
      cat ${POSSIBLE_SHOWS} | nl | sed 's/ *//' > ${FILTERED_SHOWS}
      cat ${FILTERED_SHOWS} | sed 's/\(.*\) .*/\1/'

      echo "Select a number to add a show to download list, 'a' adds all,"
      echo "0 adds nothing, and 's' allows you to search this list:"
      read NUMBER

      case ${NUMBER} in
        a|A)
          cat ${POSSIBLE_SHOWS} >> ${DOWNLOAD_LIST}
          ;;
        s|S)
          searchShows
          ;;
        0)
          ;;
        *)
          SHOWPATH=$(grep -w ^"${NUMBER}" ${FILTERED_SHOWS} | sed "s/^${NUMBER}//g" | tr -d '\t')
          echo "${SHOWPATH}" >> ${DOWNLOAD_LIST}
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
    curl -q http://tviview.abc.net.au/iview/auth/?v2 > ${AUTH_XML}
    TOKEN=$(cat ${AUTH_XML} | grep token | sed 's/.*<token>//g' | sed 's/\\&amp;/\\&/g' | sed 's,</token>.*,,g' | sed 's/ //g')
    HOST=$(cat ${AUTH_XML} | grep host | sed 's/<host>//g' | sed 's,</host>,,g' | sed 's/ //g' | tr -d '\r')

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
        ${FLVSTREAMER} --resume -r "rtmp://cp53909.edgefcs.net////flash/playback/_definst_/${SERVERPATH}" -t "rtmp://cp53909.edgefcs.net/ondemand?auth=${TOKEN}" -o "${CURDIR}"/"${FILENAME}.${SHOWEXT}" ${SWFPARAMS}
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
    'true')
      echo ${1} >> ${COMPLETE_DOWNLOADS}
      ;;
    *)
      echo ${1} >> ${INCOMPLETE_DOWNLOADS}
      ;;
  esac
}

function runDownloadShow() {
  touch ${COMPLETE_DOWNLOADS}
  touch ${INCOMPLETE_DOWNLOADS}
  LINES=$(cat ${DOWNLOAD_LIST} | wc -l | sed 's/ //g')
  echo "Number of downloads ${LINES}"

  COUNTER=0
  while [ ${COUNTER} -lt ${LINES} ]; do
    let COUNTER=COUNTER+1
    CURRENT=$(sed "${COUNTER}!d" ${DOWNLOAD_LIST})
    downloadShow "${CURRENT}"
  done

  echo
  echo
  echo "Completed Downloads:"
  cat ${COMPLETE_DOWNLOADS} | sed 's/\(.*\) .*/\1/'

  echo
  echo
  echo "Incomplete Downloads:"
  cat ${INCOMPLETE_DOWNLOADS} | sed 's/\(.*\) .*/\1/'

  mv ${INCOMPLETE_DOWNLOADS} ${DOWNLOAD_LIST}

  read -p "Press enter to continue..."
}

function convertFiles() {
  LINES=$(cat ${COMPLETE_DOWNLOADS} | wc -l | sed 's/ //g')
  echo "Number of downloads ${LINES}"

  COUNTER=0
  while [ ${COUNTER} -lt ${LINES} ]; do
    let COUNTER=COUNTER+1
    CURRENT=$(sed "${COUNTER}!d" ${COMPLETE_DOWNLOADS})

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
      cat ${DOWNLOAD_LIST}
      read -p "Press enter to continue..."
      ;;
    3)
      rm ${DOWNLOAD_LIST}
      rm ${COMPLETE_DOWNLOADS}
      rm ${INCOMPLETE_DOWNLOADS}
      ;;
    4)
      runDownloadShow
      ;;
    5)
      echo 
      cat ${COMPLETE_DOWNLOADS}
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

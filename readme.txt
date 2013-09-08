ABC iView Downloader for OSX/Linux

Changelog:
**********
-- 15/03/11 v7.0
-- Code cleanup. Removed redundant code, simpler code, more comments
	- Removed flv<=>mp4 automatic switching since it looks like everything is mp4 now and listed as such, so it's no longer an issue
-- Change download to save files with more meaningful names not just the server path.
-- Will only retry MAXRETRIES times before moving on to the next download
-- Delete items from download list after successful download. Completed items are put in "$TEMPDIR"/CompleteDownloads.txt so they can be converted if needed

-- 14/03/11 v6.9
-- Updated to combat random gzipping of indexes (Thanks to Anywho and gxdata for working out what was going on)
-- Incorporated Akamai fix (Thanks to whoever it was for finding a fix for this)

-- 05/11/10
- Updated with new auth URL

-- 17/10/10
- Updated for new index location and JSON format

-- 21/07/10
- New handshake URL
- Code cleanup. Removed more useless code.

-- 23/04/10
- Updated for new index location

-- 13/04/10
- Small change to script to porting to OSX should not require anything
- Updated for new SWF verification
- Index location small change (a-l and m-z are separate instead of all in a-z)

-- 10/04/10
- Updated to work with new indexes from ABC
- Made showlist show the full showname instead of the filename

-- 03/04/10
- Added check to speedup the download of the showlist (Series ID's are 8 chars long while others are 7)

-- 02/04/10
- Added universal rtmpdump binary (Thanks to heat_vision for instructions on how to compile)
- Changed index source to http://tvmp.abc.net.au/iview/api/?seriesIndex
- Updated for small change in ABC's JSON index

-- 05/03/10
- Added update as suggested by Steve72 to sort the show list alphabetically

-- 05/02/10
- Updated to work with ABC's new JSON index
- Changed index source to http://tvmp.abc.net.au/iview/api/?index
- Added COPYING file to comply with GPL Licence for rtmpdump

-- 23/12/09
- Changed index source to wherever http://www.abc.net.au/iview/xml/config.xml says it is
- Small changes to fix changes in index.xml
- Removed RC4 stuff since it isn't needed anymore

-- 12/12/09
- Added flv<->mp4 filename fallback
- Fixed rtmpdump parameters to resolve issue of connection dropping
- Various other small improvements

-- 08/12/09
- Changed index download source to the plaintext one at http://www.abctv.net.au/iview/api/?catalog
- Edited options in Add to download list to make them clearer

-- 23/11/09
- Updated once again to fix issues with ABC Update
- RC4 Decryptor added with key (Thanks to Anywho & lbft for the decryptor code)
- Cleanup of temp files to make things neater. All moved to ./temp/
- Added "--protocol 3" & "--skip 1" to the rtmp download commands

-- 2/10/09
- Fixed SWF Verification error

-- 28/08/09
- Added option to get shows from all channels in one list

-- 26/08/09
- Added "--resume" to flvstreamer command (will automatically resume the download if part of the file exists already)

-- 07/08/09
- Added clear list to options
- Added the option to use the previous show list to select from 
	(Lets you chose lots of programs from the same channel without redownloading all the XML files)

-- 31/07/09
- Updated to fix issues with ABC iView update

-- 29/06/09 (again again)

QUEUEING BITCHES

--29/06/09 (again)

-Used lipo to make a universal binary
-Made all the ECHO into echo

-- 29/06/09

SUPER MEGA HUGE UPDATE

- PPC Support Added!
- Updated RTMPDump to flvstreamer!
- Added reliability options!
- Added ability to manually enter a path!
- Some other stuff!
- Heavy's Minigun damage reduced
- Clearer Prompts (mostly)
- ffmpeg full support! Maintains quality!

-- 25/06/09
Added numbers to the path listings, removed the need for typing in path/filename.

-- 23/06/09
Added "Akamai" and "Normal" routes.
Added test ffmpeg functionality, makes for low quality video.

-- 16/06/09
Added functionality to be able to run directly from the finder, rather than having to execute from terminal.
Changed rtmpdump to version 1.6.

Tested on 10.5.7. Thanks to sge and Andybotter.

Doesn't match feature parity with SGE's window's batch script... yet.

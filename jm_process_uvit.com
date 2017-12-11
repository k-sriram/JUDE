;This file will run the pipeline for all the files in an observation to create
;Level 2 data photon lists and images.
;Type gdl process_uvit.com to run this program.

;The path to the JUDE procedures. Change to local path.
!path="/Users/jayanth/Dropbox/jude:"+!path

;The next two lines are specific to the local setup. Set dname to the 
;location of the Level 1 files.
spawn,"pwd",a
dname = "/Volumes/UVIT_Data/uvit/Level1" + strmid(a[0], 26)

;No changes need be made from here on.
;Process all the VIS files
jude_driver_vis,dname

;Process the UV files
tst = file_search("nuv/images/","*.fits",count=nf)
if (nf gt 0)then spawn,"gzip -f nuv/images/*.fits"
tst = file_search("nuv/events/","*.fits",count=nf)
if (nf gt 0)then spawn,"gzip -f nuv/events/*.fits"
jude_driver_uv,dname,/nuv,/notime
tst = file_search("fuv/images/","*.fits",count=nf)
if (nf gt 0)then spawn,"gzip -f fuv/images/*.fits"
tst = file_search("fuv/events/","*.fits",count=nf)
if (nf gt 0)then spawn,"gzip -f fuv/events/*.fits"
jude_driver_uv,dname,/fuv,/notime

;Identify and remove bad files.
jude_verify_Files,dname

;Merge the data and run the automated registration. Should work in most cases.
jude_uv_cleanup,/nuv
jude_uv_cleanup,/fuv
exit
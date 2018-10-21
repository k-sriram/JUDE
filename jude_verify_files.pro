pro jude_verify_files,dname
print,"Verifying VIS files"
params = jude_params()
	do_over = 0
	files=file_search(params.def_vis_dir + params.vis_l2_dir,"*.fits",count=nfiles)
	if (nfiles gt 0)then begin
		print,"gzipping FITS files"
		for ifile = 0, nfiles - 1 do spawn,"gzip -f " + files[ifile]
	endif
	
	files=file_search(params.def_vis_dir + params.vis_l2_dir,"*.fits.gz",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do begin
			im = mrdfits(files[ifile], 1, hdr, /silent, error_action=2)
			catch, error_status
			if (n_elements(im) eq 1) then begin
				print,files[ifile]," is bad"
				spawn,"rm " + files[ifile]
				do_over = 1
			endif
			catch,/cancel
		endfor
	endif
	if (do_over eq 1)then begin
		print,"Bad VIS files found: Please restart progam."
		print,"Do not delete any files."
	endif

	files=file_search(params.def_vis_dir + params.vis_add_dir,"*.fits",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do spawn,"gzip -f " + files[ifile]
	endif
	
	files=file_search(params.def_vis_dir + params.vis_add_dir,"*.fits.gz",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do begin
			im = mrdfits(files[ifile], 0, hdr, /silent, error_action=2)
			catch, error_status
			if (n_elements(im) eq 1) then begin
				print,files[ifile]," is bad"
				spawn,"rm " + files[ifile]
				do_over = 2
			endif
			catch,/cancel
		endfor
	endif
	if (do_over eq 2)then begin
		print,"Bad ADD VIS files found: Please restart progam."
		print,"Do not delete any files."
	endif

print,"Verifying NUV files"
	files=file_search(params.def_nuv_dir + params.events_dir, "*.fits", count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do spawn,"gzip -f " + files[ifile]
	endif
	
	files=file_search(params.def_nuv_dir + params.events_dir,"*.fits.gz",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do begin
			im = mrdfits(files[ifile], 1, hdr, /silent, error_action=2)
			catch, error_status
			if (n_elements(im) eq 1) then begin
				print,files[ifile]," is bad"
				spawn,"rm " + files[ifile]
				do_over = 3
			endif
			catch,/cancel
		endfor
	endif
	if (do_over eq 3)then begin
		print,"Bad NUV files found: Please restart progam."
		print,"Do not delete any files."
	endif

	files=file_search(params.def_nuv_dir + params.image_dir, "*.fits", count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do spawn,"gzip -f " + files[ifile]
	endif
	
	files=file_search(params.def_nuv_dir + params.image_dir,"*.fits.gz",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do begin
			im = mrdfits(files[ifile], 0, hdr, /silent, error_action=2)
			catch, error_status
			if (n_elements(im) eq 1) then begin
				print,files[ifile]," is bad"
				spawn,"rm " + files[ifile]
				do_over = 4
			endif
			catch,/cancel
		endfor
	endif
	if (do_over eq 4)then begin
		print,"Bad NUV image files found: Please restart progam."
		print,"Do not delete any files."
	endif

print,"Verifying FUV files"
	files=file_search(params.def_fuv_dir + params.events_dir, "*.fits", count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do spawn,"gzip -f " + files[ifile]
	endif
	
	files=file_search(params.def_fuv_dir + params.events_dir,"*.fits.gz",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do begin
			im = mrdfits(files[ifile], 1, hdr, /silent, error_action=2)
			catch, error_status
			if (n_elements(im) eq 1) then begin
				print,files[ifile]," is bad"
				spawn,"rm " + files[ifile]
				do_over = 5
			endif
			catch,/cancel
		endfor
	endif
	if (do_over eq 5)then begin
		print,"Bad FUV files found: Please restart progam."
		print,"Do not delete any files."
	endif

	files=file_search(params.def_fuv_dir + params.image_dir, "*.fits", count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do spawn,"gzip -f " + files[ifile]
	endif
	
	files=file_search(params.def_fuv_dir + params.image_dir,"*.fits.gz",count=nfiles)
	if (nfiles gt 0)then begin
		for ifile = 0, nfiles - 1 do begin
			im = mrdfits(files[ifile], 0, hdr, /silent, error_action=2)
			catch, error_status
			if (n_elements(im) eq 1) then begin
				print,files[ifile]," is bad"
				spawn,"rm " + files[ifile]
				do_over = 6
			endif
			catch,/cancel
		endfor
	endif
	if (do_over eq 6)then begin
		print,"Bad FUV image files found: Please restart progam."
		print,"Do not delete any files."
	endif
	
if (do_over eq 0)then begin
	print,"All files verified."
	openw,verify_lun,"JUDE_VERIFY_FILES_DONE",/get
	printf,verify_lun,"No need to run process_uvit.com: only jude_uv_cleanup."
	free_lun,verify_lun
endif else exit
end
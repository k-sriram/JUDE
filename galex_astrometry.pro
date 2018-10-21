;+
; NAME:		ASTROMETRY
; PURPOSE:	Apply astrometry to one image by comparison with another that is
;			already corrected
; CALLING SEQUENCE:
; astrometry, new_file, ref_file, both_same = both_same, ref_stars = ref_stars
; INPUTS:
;	New_file		: File to be corrected astrometrically.
;	Ref_file		: File with accurate astrometry
; OUTPUTS:
;	None			: New file is updated with correct astrometry
; OPTIONAL INPUT KEYWORDS:
;	Both_same		: If set, there is no rotation between files. Otherwise,
;					  the NUV data have to be rotated and reflected.
;	Ref_stars		: array with two rows: ra and dec
; NOTES:
;					Data files are written out as per the original names
;NOTE THAT THIS PROGRAM IS NOT SUPPORTED EXCEPT IN THE VERY SPECIFIC USE
;CASE: GALEX REFERENCE IMAGE, UVIT OUTPUT IMAGE. CHANGES WILL HAVE TO BE
;MADE OTHERWISE.
; MODIFICATION HISTORY:
;	JM: Aug. 18, 2017
;	JM: Jan. 20, 2018
;	JM: May  31, 2018: Bug if there were three points
;Copyright 2016 Jayant Murthy
;
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;
;       http://www.apache.org/licenses/LICENSE-2.0
;
;   Unless required by applicable law or agreed to in writing, software
;   distributed under the License is distributed on an "AS IS" BASIS,
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;   See the License for the specific language governing permissions and
;   limitations under the License.
;
;-

pro calc_scale,new_im, rxscale, ryscale, rxsize, rysize, rxmax, rymax
	refsize = size(new_im,/dimensions)
	rxscale = refsize[0]/512
	ryscale = refsize[1]/512
	rxsize = refsize[0]/rxscale
	rysize = refsize[1]/ryscale
	rxmax = rxsize*rxscale
	rymax = rysize*ryscale
end

;**********************DISPLAY PROGRAMS ***********************
pro display_image, new_im, new_max_value, x, y, xoff, yoff
	calc_scale,new_im, rxscale, ryscale, rxsize, rysize, rxmax, rymax
	tv,bytscl(rebin(new_im[0:rxmax-1,0:rymax-1], rxsize, rysize), 0, new_max_value),xoff,yoff
	plots,/dev,x/rxscale + xoff,y/ryscale + yoff,psym=4,col=255,symsize=3
end

function set_limits, grid2, xstar, ystar, boxsize, resolution,$
					xmin = xmin, ymin = ymin, display = display
	siz = size(grid2)
	ndim = siz[1]
	xmin = xstar - boxsize*resolution
	xmax = xstar + boxsize*resolution
	ymin = ystar - boxsize*resolution
	ymax = ystar + boxsize*resolution

	xmin = 0 > xmin < (ndim - 1)
	xmax = (xmin + 1) > xmax < (ndim - 1)
	ymin = 0 > ymin < (ndim - 1)
	ymax = (ymin + 1) > ymax < (ndim - 1)

	if (keyword_set(display))then begin
		plots,/dev, [xmin, xmin, xmax, xmax, xmin]/resolution,$
					[ymin, ymax, ymax, ymin, ymin]/resolution,$
					col=255,thick=2
	endif
	if (((xmax - xmin) lt 5) or ((ymax - ymin) lt 5)) then begin
		h1 = fltarr(2*boxsize*resolution, 2*boxsize*resolution)
	endif else h1 = grid2[xmin:xmax, ymin:ymax]
return,h1
end
;*****************END DISPLAY PROGRAMS***************************

function read_image_data, new_file, ref_file, new_im, new_time, new_hdr, ref_im, ref_hdr, $
		ref_max_value, new_max_value, ra_cent, dec_cent, ref_detector, new_detector
		new_im   = mrdfits(new_file, 0, new_hdr, /silent)
	new_time = mrdfits(new_file, 1, new_thdr, /silent)
	if (n_elements(new_time) eq 1)then new_time = new_im*0 + 1
	ref_im   = mrdfits(ref_file, 0, ref_hdr, /silent)
	ref_time = mrdfits(ref_file, 1, thdr,/silent)
	if (n_elements(ref_time) eq 0)then ref_time = ref_im*0 + 1
	q=where(ref_time eq 0,nq)
	if (nq gt 0)then ref_im[q] = 0
	if (strcompress(sxpar(ref_hdr, "INSTRUME"),/rem) eq "UVIT") then begin
		if (strcompress(sxpar(ref_hdr, "ASTRDONE"),/rem) ne "TRUE")then begin
			print,"No astrometry done on reference image"
			return, 0
		endif
	endif
	if (strcompress(sxpar(new_hdr, "ASTRDONE"),/rem) eq "TRUE")then begin
		ans=''
		read,"Astrometry already done, continue?",ans
		if (ans ne 'y')then return,0
	endif

	ans='y'
	while (ans eq 'y')do begin
		tv,bytscl(rebin(new_im,512,512),0,new_max_value)
		ans_val = ""
		print,"Current image scaling is ",new_max_value," Enter new value (else return)."
		read,ans_val
		if (ans_val ne "") then new_max_value = float(ans_val) else ans = 'n'
	endwhile
	ans='y'
	while (ans eq 'y')do begin
		calc_scale,ref_im, rxscale, ryscale, rxsize, rysize, rxmax, rymax
		tv,bytscl(rebin(ref_im[0:rxmax-1,0:rymax-1], rxsize, rysize), 0, ref_max_value),512,0
		ans_val = ""
		print,"Current image scaling is ",ref_max_value," Enter new value (else return)."
		read,ans_val
		if (ans_val ne "") then ref_max_value = float(ans_val) else ans = 'n'
	endwhile
	ra_cent  = sxpar(ref_hdr, "crval1")
	dec_cent = sxpar(ref_hdr, "crval2")
	if (strcompress(sxpar(ref_hdr,"INSTRUME"),/rem) eq "UVIT") then $
		ref_detector = strcompress(sxpar(ref_hdr, "detector"),/rem) else $
		ref_detector = ""
		
	if(strcompress(sxpar(new_hdr, "INSTRUME"),/rem) eq "UVIT") then $
		new_detector = strcompress(sxpar(new_hdr, "detector"),/rem) else $
		new_detector = ""
return,1
end

function check_star_position, new_im, xstar, ystar,new_max_value, xmin, ymin
	boxsize = 20
	siz = size(new_im, /dimension)
	resolution = siz[0]/512
	
	h1 = set_limits(new_im, xstar, ystar, boxsize, resolution, xmin = xmin, ymin = ymin)
	siz = size(h1, /dimensions)
	r1 = mpfit2dpeak(h1, a1)
	if (finite(a1[4]) and finite(a1[5]))then begin
		xstar = xmin + a1[4]
		ystar = ymin + a1[5]
	endif else begin
		tcent = total(h1)
		xcent = total(total(h1, 2)*indgen(siz[0]))/tcent
		ycent = total(total(h1, 1)*indgen(siz[1]))/tcent
		xstar = xmin + xcent
		ystar = ymin + ycent
	endelse
	boxsize = 5
	h1 = set_limits(new_im, xstar, ystar, boxsize, resolution, xmin = xmin, ymin = ymin)
	siz = size(h1, /dimensions)
	r1 = mpfit2dpeak(h1, a1)
	if (finite(a1[4]) and finite(a1[5]) and (a1[1] gt 0))then begin
		xstar = xmin + a1[4]
		ystar = ymin + a1[5]
		star_found = 1
	endif else begin
		star_found = 0
	endelse
	wset,1
	erase
	tv,bytscl(rebin(h1,siz[0]*(640/siz[0]),siz[1]*(640/siz[1])) ,0,new_max_value)
	plots,(xstar - xmin)*(640/siz[0]),(ystar - ymin)*(640/siz[1]),/psym,symsize=3,col=255,/dev,thick=2

wset,0
	return,star_found
end
;********************************* BEGIN MAIN PROGRAM *******************************
pro galex_astrometry, new_file, ref_file, $
new_max_value = new_max_value, ref_max_value = ref_max_value,$
nocheck = nocheck, force_solve=force_solve, debug = debug,$
star_pos = star_pos


;Initialization
	if (n_elements(new_max_value) eq 0)then new_max_value = 0.0002
	if (n_elements(ref_max_value) eq 0)then ref_max_value = 0.002
	device, window_state = window_state
	if (window_state[0] eq 0)then $
		window, 0, xs = 1024, ys = 512, xp = 10, yp = 500
	if (window_state[0] eq 0)then $
		window, 1, xs = 640,  ys = 640,yp = 600
	wset,0

;Read data from image files
	success = read_image_data(new_file, ref_file, new_im, new_time, new_hdr, ref_im, ref_hdr,$
			ref_max_value, new_max_value, ra_cent, dec_cent, ref_detector, new_detector)
			extast, ref_hdr, ref_astr
	if (success eq 0)then goto, noproc
	
;Assume that the pixels are square
	ref_naxis = size(ref_im, /dimensions)
	cdelt1 = sxpar(ref_hdr,"CDELT2")*3600.
	uvit_scale = 28.*60./4096. 

;I'VE USED THREE POINTS FOR THE ASTROMETRIC CORRECTION. ONE MAY WANT MORE.
	npoints = 0
	calc_scale,ref_im, rxscale, ryscale, rxsize, rysize
	calc_scale,new_im, nxscale, nyscale, nxsize, nysize
	if (not(keyword_set(force_solve)))then maxnpoints = 3
	xref = fltarr(maxnpoints)
	yref = xref
	newxp = xref
	newyp = xref
	
	
;Let's pick two stars in the UVIT image
	print,"Select two stars in the UVIT image (on the left)"
	a = 1000
		while (a gt 512) do begin
			print,"On the left"
			cursor,a,b,/dev & print,a,b
			if (a gt 512)then print,"Invalid point clicked"
			wait,1 ;(Avoiding double clicks)
		endwhile
		a = a*nxscale
		b = b*nyscale
		star_found = check_star_position(new_im, a, b, new_max_value, xmin, ymin)
		newxp[0] = a
		newyp[0] = b
		a=1000
		while (a gt 512) do begin
			print,"Second star on the left"
			cursor,a,b,/dev & print,a,b
			if (a gt 512)then print,"Invalid point clicked"
			wait,1 ;(Avoiding double clicks)
		endwhile
		a = a*nxscale
		b = b*nyscale
		star_found = check_star_position(new_im, a, b, new_max_value, xmin, ymin)

		newxp[1] = a
		newyp[1] = b
		duvit = sqrt((newxp[1] - newxp[0])^2 + (newyp[1] - newyp[0])^2)*uvit_scale
	
;Now pick GALEX stars
pickgalex:
		print,"Pick the same two GALEX stars (on the right)."
		a = 0
		while (a lt 512) do begin
			print,"Pick first Galex star on the right."
			cursor,a,b,/dev & print,a,b
			if (a lt 512)then print,"Invalid point clicked"
			wait,1 ;(Avoiding double clicks)
		endwhile
		a = (a - 512)*rxscale
		b = b*ryscale
		star_found = check_star_position(ref_im, a, b, ref_max_value, xmin, ymin)
		xref[0] = a
		yref[0] = b
		a=0
		while (a lt 512) do begin
			print,"Pick second Galex star on the right."
			cursor,a,b,/dev & print,a,b
			if (a lt 512)then print,"Invalid point clicked"
			wait,1 ;(Avoiding double clicks)
		endwhile
		a = (a - 512)*rxscale
		b = b*ryscale
		star_found = check_star_position(ref_im, a, b, ref_max_value, xmin, ymin)
		xref[1] = a
		yref[1] = b
		dgalex = sqrt((xref[1] - xref[0])^2 + (yref[1] - yref[0])^2)*cdelt1
		print,"UVIT separation in arcseconds is: ",duvit
		print,"Galex separation in arcseconds is: ",dgalex
		ans="y"
		read,"Are these two stars ok? If not let's pick two different stars.",ans
		if (ans eq "n")then goto,pickgalex
npoints = 2
;Add a third star
pickgalex2:
read,"Is there a third star (n if there is none)",ans
	if (ans ne 'n')then begin
		a = 1000
		while (a gt 512) do begin
			print,"Pick the third UVIT star (on the left)."
			cursor,a,b,/dev & print,a,b
			if (a gt 512)then print,"Invalid point clicked"
			wait,1 ;(Avoiding double clicks)
		endwhile
		a = a*nxscale
		b = b*nyscale
		star_found = check_star_position(new_im, a, b, new_max_value, xmin, ymin)
		newxp[2] = a
		newyp[2] = b
		a = 0
		while (a lt 512) do begin
			print,"Pick the third Galex star (on the right)."
			cursor,a,b,/dev & print,a,b
			if (a lt 512)then print,"Invalid point clicked"
			wait,1 ;(Avoiding double clicks)
		endwhile
		a = (a - 512)*rxscale
		b = b*ryscale
		star_found = check_star_position(ref_im, a, b, new_max_value, xmin, ymin)
		xref[2] = a
		yref[2] = b
		duvit = sqrt((newxp[2] - newxp[0])^2 + (newyp[2] - newyp[0])^2)*uvit_scale
		dgalex = sqrt((xref[2] - xref[0])^2 + (yref[2] - yref[0])^2)*cdelt1
		print,"UVIT separation in arcseconds is: ",duvit
		print,"Galex separation in arcseconds is: ",dgalex
		ans="y"
		read,"Is this star ok? If not let's pick a different stars.",ans
		if (ans eq "n")then goto,pickgalex2 else npoints = 3
	endif
	xref = xref[0:npoints - 1]
	yref = yref[0:npoints - 1]
	newxp = newxp[0:npoints - 1]
	newyp = newyp[0:npoints - 1]
	xyad, ref_hdr, xref, yref, newra, newdec	
;If we have already defined the stars to be used for astronometry
begin_corr:
;Calculate astrometry using either solve astro or starast	
	if ((n_elements(newxp) gt 5) and ((keyword_set(force_solve))))then begin
		astr = solve_astro(newra, newdec, newxp, newyp, distort = 'tnx')
		putast, new_hdr, astr
	endif else if (n_elements(newra) gt 2)then begin
		newra  = newra[0:npoints-1]
		newdec = newdec[0:npoints-1]
		newxp = newxp[0:npoints-1]
		newyp = newyp[0:npoints-1]			
		starast, newra, newdec, newxp, newyp, cd, hdr=new_hdr
	endif else if (n_elements(newra) eq 2)then begin
		starast, newra, newdec, newxp, newyp, cd, hdr=new_hdr,/right
	endif else begin
		print,"Not enough stars"
		goto,noproc
	endelse

;Update the file header
	sxaddpar,new_hdr,"ASTRDONE","TRUE"
	f1 = strpos(new_file, "fits")
	t = strmid(new_file, 0, f1) + "fits"
	mwrfits,new_im, t, new_hdr, /create
	mwrfits, new_time, t, new_thdr
	spawn,"gzip -fv " + t
noproc:	
end
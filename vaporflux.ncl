load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
external  MY "/home/donglx/software/ncl_scripts/vaporflux.so"
begin
  time1=systemfunc("date '+it is：%M:%S '" )
  print(time1)                                                    ;查看系统时间，比对运行时间
  ;========================
  ; get list of all files and open as "one big file"
  ;========================                             
    all_files0302 = systemfunc ("ls /home/donglx/data/fnl_data/fnl_201207*")
    fall0302      = addfiles (all_files0302+".grb", "r")                         ; note the "s" of addfile
  ;========================
  ; choose how files are combined and read in variable across files
  ;========================  
    ListSetType (fall0302, "join")             ; concatenate or "merge" (default)
    t0302       = fall0302[:]->TMP_3_ISBL                        ;(ncljoin,lv_ISBL3, lat_3, lon_3)
    u0302       = fall0302[:]->U_GRD_3_ISBL                      ;(ncljoin,lv_ISBL3, lat_3, lon_3)
    v0302       = fall0302[:]->V_GRD_3_ISBL 
    rhprs0302   = fall0302[:]->R_H_3_ISBL                        ;(ncljoin,lv_ISBL7, lat_3, lon_3)
    pre         = fall0302[0]->lv_ISBL3                           ;(10:1000)
    pre_7       = fall0302[0]->lv_ISBL7                           ;(100:1000)

      
;##########################################################################################
;设置常量，计算变量
;###########################################################################################    
   radius   =  20
   g        =  9.8

  ;*******************************************************************************************************
  ;提取变量
  ;***********************************************************************************************************
  p     =pre(20)                                     ;850hPa
  t     =t0302(:,{850},{10:50},{100:140})
  rhprs =rhprs0302(:,{850},{10:50},{100:140})
  u     =u0302(:,{850},{10:50},{100:140})
  v     =v0302(:,{850},{10:50},{100:140})
 qu     =new((/9,41,41/),float)
 qv     =new((/9,41,41/),float)
 mm     =new((/9,41,41/),float)

;******************************************************************************************* 
;计算水汽通量
;*********************************************************************************************
xx=41
yy=41
zz=1
tt=9
  
   MY::vaporflux(p,t,rhprs,u,v,qu,qv,mm,xx,yy,zz,tt,g)
    
    printVarSummary(qu) 
    
    copy_VarMeta(u,qu)
    copy_VarMeta(v,qv)
    copy_VarMeta(rhprs,mm)

   printVarSummary(qu)

;=====================================================================================================
;plot
;=====================================================================================================


    res = True
    res@gsnAddCyclic  = False 
    res@gsnDraw      = False                        ; don't draw yet
    res@gsnFrame     = False                        ; don't advance frame yet
 
    res@tmXBMode            = "Explicit"
    res@tmXBValues          = ispan(0,40,5)
    res@tmXBLabels          = (/"-20","-15","-10","-5","0","5","10","15","20"/)
    res@tmYLMode            = "Explicit"
    res@tmYLValues          = ispan(0,40,5)
    res@tmYLLabels          = (/"-20","-15","-10","-5","0","5","10","15","20"/)
    res@tmXBLabelFontHeightF = 0.02	
    res@tmYLLabelFontHeightF = 0.02
    res@tiMainString          =""
                                       
    res@vcLineArrowThicknessF  = 2.0
    res@vcRefAnnoOrthogonalPosF  = 0            ;ref的位置
    res@vcRefAnnoString1On      = True
    res@vcRefAnnoString2On      = False
    res@vcRefMagnitudeF         = 20                 ; make vectors larger
    res@vcRefLengthF            = 0.1               ; ref vec length
    res@vcGlyphStyle            = "CurlyVector"     ; turn on curly vectors
    res@vcMinDistanceF          =0.02                ;箭头疏密
    
    
    res@vcVectorDrawOrder= "PostDraw" 
    res@gsnLeftString =""
    res@gsnRightString =""
    res@tiMainString =""

    
    cnres                 = True                    ; plot mods desired
    cnres@gsnDraw         = False                   ; don't draw yet
    cnres@gsnFrame        = False                   ; don't advance frame yet
    cnres@cnFillOn        = True                    ; turn on color
    cnres@gsnSpreadColors = True                    ; use full colormap 
    cnres@gsnSpreadColorStart = 0
    cnres@gsnSpreadColorEnd   = 201
    cnres@cnLinesOn       = False                   ; turn off contour lines
    cnres@cnLineLabelsOn  = False                   ; tuen off line labels
    cnres@cnInfoLabelOn =False 
	
	
    cnres@cnLevelSelectionMode = "ManualLevels"
    cnres@cnMinLevelValF    = 8
    cnres@cnMaxLevelValF   = 42
    cnres@cnLevelSpacingF   =2
	
    cnres@gsnLeftString =""
    cnres@gsnRightString =" g s~S~ -1~N~cm~S~ -1~N~hPa~S~ -1"
    cnres@tiMainString =""
    cnres@lbLabelBarOn           = False   

    
	mm=smth9(mm,0.5,-0.25,False)

    printMinMax (mm*1000, True) 
  dir = "/home/donglx/software/ncl_scripts"
   wks = gsn_open_wks("x11","850hpa+vapour_flux(0+18)")                  ; open a ps file
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")	
   
   print("====plot..........===========")	
   plots = new((/2,13/),graphic) 
   do j=0,8
       if(j.eq.3) then
         res@vcRefAnnoOn = True
       else
         res@vcRefAnnoOn = False
       end if
     plots(0,j) =gsn_csm_vector(wks,qu(j,:,:)*1000,qv(j,:,:)*1000,res)  ; create plot 
     plots(1,j) = gsn_csm_contour(wks,mm(j,:,:)*1000,cnres)
     overlay(plots(0,j),plots(1,j))
   end do
   

  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnPanelLabelBar = True                   ; add common colorbar
  resP@gsnMaximize      = True
  resP@pmLabelBarWidthF      = 0.6               ; default is shorter
  resP@pmLabelBarHeightF     = 0.03               ; default is taller 
  resP@pmLabelBarOrthogonalPosF = 0          ; move label bar closer
  resP@lbLabelFontHeightF    = .012              ; default is HUGE
  resP@gsnPanelBottom   = 0.00                   ; add space at bottom
  resP@gsnPanelYWhiteSpacePercent = 0
  resP@gsnPanelXWhiteSpacePercent = 0
  

  resP@gsnPanelFigureStrings= (/"0h)","6h)","12h)","18h)"/) ; add strings to panel
  resP@amJust   = "TopLeft"

  gsn_panel(wks,plots(0,3:6),(/2,2/),resP)               ; now draw as one plot
  
  frame(wks)
  time2=systemfunc("date '+it is：%M:%S '" )
  print(time2)
;#################################################################################################
 end
  
  

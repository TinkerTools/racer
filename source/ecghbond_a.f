c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #############################################################
c     ##                                                         ##
c     ##  subroutine ecghbond  --  CG H-bond potential energy    ##
c     ##                                                         ##
c     #############################################################
c
c
c     "ecghbond" calculates the CG H-bond potential energy;
c
c
      subroutine ecghbond
      use sizes
      use angbnd
      use angpot
      use atoms
      use bound
      use energi
      use group
      use math
      use usage
      use vdwpot
      implicit none
      integer i,ia,ib,ic,id
      integer j,ja,jb,jc,jd
      real*8 rhbond,rhbond2
      real*8 xia,yia,zia
      real*8 xib,yib,zib
      real*8 xic,yic,zic
      real*8 xip,yip,zip
      real*8 xja,yja,zja
      real*8 xjb,yjb,zjb
      real*8 xjc,yjc,zjc
      real*8 xjp,yjp,zjp    
      real*8 rip,rjp            
      real*8 e,ecghbo
      real*8 doti,cosinei
      real*8 dotj,cosinej
      real*8 anglei,anglej,anglek,fgrp
      real*8 rx,ry,rz
      real*8 xiab,yiab,ziab
      real*8 xicb,yicb,zicb
      real*8 xjab,yjab,zjab
      real*8 xjcb,yjcb,zjcb
      real*8 cghbondcutoff2
      real*8 r03
      logical proceed
c     
c     Constants,    ehbmax,hbondmin,cghbondcutoff in prmkey.f and vdwpot

      r03 = hbondmin*hbondmin*hbondmin

      cghbondcutoff2 = cghbondcutoff*cghbondcutoff
c      write (*,*) "Use CG H-bond, magnitude = ",  ehbmax, hbondmin,
c     &                 cghbondcutoff   
c      write (*,*) "Use CG H-bond"
c
c
c     zero out the angle bending energy component
c
      ecghb = 0.0d0
c
c
c     decide whether to compute the current interaction
c
         proceed = .true.
c         if (use_group)  call groups (proceed,fgrp,ia,ib,ic,0,0,0)
c         if (proceed)  proceed = (use(ia) .or. use(ib) .or. use(ic))         
c      

c
c     initialize local variables for OpenMP calculation
c
      ecghbo = ecghb 
c
c     set OpenMP directives for the major loop structure
c
!$OMP PARALLEL default(private) shared(nangle,iang,x,y,z,
!$OMP& ehbmax,cghbondcutoff2,r03,type)
!$OMP& shared(ecghbo)
!$OMP DO reduction(+:ecghbo) schedule(guided)

c
c     calculate the bond angle bending energy term
c
      do i = 1, nangle
         ib = iang(2,i)
         ia = iang(1,i)
         ic = iang(3,i)
c     determine atom type is N6 N2 O6 O2 4 5 6 7    
         if ((type(ib) .GT. 3) .AND. (type(ib) .LT. 8)) then
         xib = x(ib)
         yib = y(ib)
         zib = z(ib)
c         write (*,*) "ia ib ic",ia,ib,ic
        do j = i+1, nangle
            jb = iang(2,j)
            if ((type(jb) .GT. 3) .AND. (type(jb) .LT. 8)) then
            xjb = x(jb)
            yjb = y(jb)
            zjb = z(jb)    
            rx = xib - xjb
            ry = yib - yjb
            rz = zib - zjb               
            rhbond2 = rx*rx + ry*ry + rz*rz
            rhbond = sqrt(rhbond2)
            if (rhbond2 .lt. cghbondcutoff2) then
              xia = x(ia)
              yia = y(ia)
              zia = z(ia)
              xic = x(ic)
              yic = y(ic)
              zic = z(ic)
              ja = iang(1,j)
              jc = iang(3,j)             
              xja = x(ja)
              yja = y(ja)
              zja = z(ja)
              xjc = x(jc)
              yjc = y(jc)
              zjc = z(jc) 
c     determine the atoms involved is H-bond atoms
          if (((((type(ib) .eq. 6) .and. ((type(ia) .eq. 5) 
     &                      .or. (type(ic) .eq. 5))) .and.    
     &         ((type(jb) .eq. 4) .and. ((type(ja) .eq. 7) 
     &                      .or. (type(jc) .eq. 7)))) .or.      
     &        (((type(ib) .eq. 4) .and. ((type(ia) .eq. 9) 
     &                      .or. (type(ic) .eq. 9))) .and.    
     &         ((type(jb) .eq. 6) .and. ((type(ja) .eq. 7)
     &                      .or. (type(jc) .eq. 7)))) .or.     
     &        (((type(ib) .eq. 4) .and. ((type(ia) .eq. 7)
     &                      .or. (type(ic) .eq. 7))) .and.    
     &         ((type(jb) .eq. 6) .and. ((type(ja) .eq. 5)
     &                      .or. (type(jc) .eq. 5)))) .or.      
     &        (((type(ib) .eq. 6) .and. ((type(ia) .eq. 7)
     &                      .or. (type(ic) .eq. 7))) .and.    
     &         ((type(jb) .eq. 4) .and. ((type(ja) .eq. 9)
     &                      .or. (type(jc) .eq. 9)))) .or.       
     &        (((type(ib) .eq. 5) .and. ((type(ia) .eq. 6) 
     &                      .or. (type(ic) .eq. 6))) .and.    
     &         ((type(jb) .eq. 7) .and. ((type(ja) .eq. 4)
     &                      .or. (type(jc) .eq. 4)))) .or.    
     &        (((type(ib) .eq. 7) .and. ((type(ia) .eq. 4)
     &                      .or. (type(ic) .eq. 4))) .and.   
     &         ((type(jb) .eq. 5) .and. ((type(ja) .eq. 6) 
     &                    .or. (type(jc) .eq. 6))))) .and.
     &     (((ib - jb) .gt. 10) .or. ((jb-ib) .gt. 10)))  then     
c     compute the value of the 1st angle i (alpha) 
              xiab = xia - xib
              yiab = yia - yib
              ziab = zia - zib
              xicb = xic - xib
              yicb = yic - yib
              zicb = zic - zib    
              xip = yiab*zicb - yicb*ziab
              yip = -1*xiab*zicb + xicb*ziab
              zip = xiab*yicb - xicb*yiab
              rip = sqrt(xip*xip + yip*yip + zip*zip)
              rip = max(rip,0.001d0)
              doti = xip*rx + yip*ry + zip*rz
              cosinei = doti / (rip*rhbond) 
              cosinei = min(1.0d0,max(-1.0d0,cosinei))
              anglei = acos(cosinei)
c     computer the second angle j (beta)         
              xjab = xja - xjb
              yjab = yja - yjb
              zjab = zja - zjb
              xjcb = xjc - xjb
              yjcb = yjc - yjb
              zjcb = zjc - zjb    
              xjp = yjab*zjcb - yjcb*zjab
              yjp = -1*xjab*zjcb + xjcb*zjab
              zjp = xjab*yjcb - xjcb*yjab
              rjp = sqrt(xjp*xjp + yjp*yjp + zjp*zjp)
              rjp = max(rjp,0.001d0)
              dotj = xjp*rx + yjp*ry + zjp*rz
              cosinej = dotj / (rjp*rhbond) 
              cosinej = min(1.0d0,max(-1.0d0,cosinej))
              anglej = acos(cosinej)
              anglek = anglei + anglej
              if (anglek .gt. (pi/2) .and. anglek .lt. (3*pi/2)) then
               if (anglek .gt. pi) anglek = 2*pi - anglek
               anglek = anglek*2 - pi
               e =-1.0d0*(ehbmax/2)*(1-cos(anglek))*
     &                  (r03/(rhbond2*rhbond))
              else 
               e = 0.0d0
              end if
              ecghbo = ecghbo + e
c              write (*,*) "ecghb", e, ib, jb, type(ib), type(jb), 
c     &             radian *anglei, radian *anglej, radian *anglek
             end if
            end if
           end if 
          end do
        end if
      end do
c
c     end OpenMP directives for the major loop structure
c
!$OMP END DO
!$OMP END PARALLEL
c
c     add local copies to global variables for OpenMP calculation
c
      ecghb = ecghbo

      return
      end

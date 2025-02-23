c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###############################################################
c     ##                                                           ##
c     ##  subroutine elj2  --  atom-by-atom Lennard-Jones Hessian  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "elj2" calculates the Lennard-Jones 6-12 van der Waals second
c     derivatives for a single atom at a time
c
c
      subroutine elj2 (i,xred,yred,zred)
      use sizes
      use warp
      implicit none
      integer i
      real*8 xred(*)
      real*8 yred(*)
      real*8 zred(*)
      real*8 eps
c
c
c     choose the method for summing over pairwise interactions
c
      if (use_stophat) then
         call elj2c (i,xred,yred,zred)
      else if (use_smooth) then
         call elj2b (i,xred,yred,zred)
c      else if (use_leepinglj) then
c         call elj2_lp (i,xred,yred,zred)
      else
         call elj2a (i,xred,yred,zred)
      end if
      return
      end
cc
cc
cc     ###############################################################   
cc     ##                                                           ##
cc     ##  subroutine elj2_lp  --  double loop Lennard-Jones Hessian  ##
cc     ##                                                           ##
cc     ###############################################################
cc
cc
cc     "elj2a" calculates the Lennard-Jones 6-12 van der Waals second
cc     derivatives using a double loop over relevant atom pairs
cc
cc
c      subroutine elj2_lp (iatom,xred,yred,zred)
c      use sizes
c      use atomid
c      use atoms
c      use bound
c      use cell
c      use couple
c      use group
c      use hessn
c      use shunt
c      use vdw
c      use vdwpot
c      implicit none
c      integer i,j,k
c      integer ii,iv,it
c      integer kk,kv,kt
c      integer iatom,jcell
c      integer nlist,list(5)
c      integer, allocatable :: iv14(:)
c      real*8 e,de,d2e,fgrp
c      real*8 p6,p12,eps,rv
c      real*8 xi,yi,zi
c      real*8 xr,yr,zr
c      real*8 redi,rediv
c      real*8 redk,redkv
c      real*8 redi2,rediv2
c      real*8 rediiv
c      real*8 redik,redivk
c      real*8 redikv,redivkv
c      real*8 rik,rik2,rik3
c      real*8 rik4,rik5
c      real*8 taper,dtaper
c      real*8 d2taper
c      real*8 d2edx,d2edy,d2edz
c      real*8 term(3,3)
c      real*8 xred(*)
c      real*8 yred(*)
c      real*8 zred(*)
c      real*8, allocatable :: vscale(:)
c      logical proceed
c      character*6 mode
cc
cc
cc     perform dynamic allocation of some local arrays
cc
c      allocate (iv14(n))
c      allocate (vscale(n))
cc
cc     set arrays needed to scale connected atom interactions
cc
c      do i = 1, n
c         vscale(i) = 1.0d0
c         iv14(i) = 0
c      end do
cc
cc     set the coefficients for the switching function
cc
c      mode = 'VDW'
c      call switch (mode)
cc
cc     check to see if the atom of interest is a vdw site
cc
c      nlist = 0
c      do k = 1, nvdw
c         if (ivdw(k) .eq. iatom) then
c            nlist = nlist + 1
c            list(nlist) = iatom
c            goto 10
c         end if
c      end do
c      return
c   10 continue
cc
cc     determine the atoms involved via reduction factors
cc
c      nlist = 1
c      list(nlist) = iatom
c      do k = 1, n12(iatom)
c         i = i12(k,iatom)
c         if (ired(i) .eq. iatom) then
c            nlist = nlist + 1
c            list(nlist) = i
c         end if
c      end do
cc
cc     find van der Waals Hessian elements for involved atoms
cc
c      do ii = 1, nlist
c         i = list(ii)
c         iv = ired(i)
c         redi = kred(i)
c         if (i .ne. iv) then
c            rediv = 1.0d0 - redi
c            redi2 = redi * redi
c            rediv2 = rediv * rediv
c            rediiv = redi * rediv
c         end if
c         it = jvdw(i)
c         xi = xred(i)
c         yi = yred(i)
c         zi = zred(i)
cc
cc     set interaction scaling coefficients for connected atoms
cc
c         do j = 1, n12(i)
c            vscale(i12(j,i)) = v2scale
c         end do
c         do j = 1, n13(i)
c            vscale(i13(j,i)) = v3scale
c         end do
c         do j = 1, n14(i)
c            vscale(i14(j,i)) = v4scale
c            iv14(i14(j,i)) = i
c         end do
c         do j = 1, n15(i)
c            vscale(i15(j,i)) = v5scale
c         end do
cc
cc     decide whether to compute the current interaction
cc
c         do kk = 1, nvdw
c            k = ivdw(kk)
c            kv = ired(k)
c            proceed = .true.
c            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
c            if (proceed)  proceed = (k .ne. i)
cc
cc     compute the Hessian elements for this interaction
cc
c            if (proceed) then
c               kt = jvdw(k)
c               xr = xi - xred(k)
c               yr = yi - yred(k)
c               zr = zi - zred(k)
c               call image (xr,yr,zr)
c               rik2 = xr*xr + yr*yr + zr*zr
cc
cc     check for an interaction distance less than the cutoff
cc
c               if (rik2 .le. off2) then
c                  rv = radmin(kt,it)
c                  eps = epsilon(kt,it)
c                  if (iv14(k) .eq. i) then
c                     rv = radmin4(kt,it)
c                     eps = epsilon4(kt,it)
c                  end if
c                  eps = eps * vscale(k)
c                  rik = sqrt(rik2)
c                  p6 = rv**6 / rik2**3
c                  p12 = p6 * p6
c                  de = eps * (p12-p6) * (-12.0d0/rik)
c                  d2e = eps * (13.0d0*p12-7.0d0*p6) * (12.0d0/rik2)
cc
cc     use energy switching if near the cutoff distance
cc
c                  if (rik2 .gt. cut2) then
c                     e = eps * (p12-2.0d0*p6)
c                     rik3 = rik2 * rik
c                     rik4 = rik2 * rik2
c                     rik5 = rik2 * rik3
c                     taper = c5*rik5 + c4*rik4 + c3*rik3
c     &                          + c2*rik2 + c1*rik + c0
c                     dtaper = 5.0d0*c5*rik4 + 4.0d0*c4*rik3
c     &                           + 3.0d0*c3*rik2 + 2.0d0*c2*rik + c1
c                     d2taper = 20.0d0*c5*rik3 + 12.0d0*c4*rik2
c     &                            + 6.0d0*c3*rik + 2.0d0*c2
c                     d2e = e*d2taper + 2.0d0*de*dtaper + d2e*taper
c                     de = e*dtaper + de*taper
c                  end if
cc
cc     scale the interaction based on its group membership
cc
c                  if (use_group) then
c                     de = de * fgrp
c                     d2e = d2e * fgrp
c                  end if
cc
cc     get chain rule terms for van der Waals Hessian elements
cc
c                  de = de / rik
c                  d2e = (d2e-de) / rik2
c                  d2edx = d2e * xr
c                  d2edy = d2e * yr
c                  d2edz = d2e * zr
c                  term(1,1) = d2edx*xr + de
c                  term(1,2) = d2edx*yr
c                  term(1,3) = d2edx*zr
c                  term(2,1) = term(1,2)
c                  term(2,2) = d2edy*yr + de
c                  term(2,3) = d2edy*zr
c                  term(3,1) = term(1,3)
c                  term(3,2) = term(2,3)
c                  term(3,3) = d2edz*zr + de
cc
cc     increment diagonal and non-diagonal Hessian elements
cc
c                  if (i .eq. iatom) then
c                     if (i.eq.iv .and. k.eq.kv) then
c                        do j = 1, 3
c                           hessx(j,i) = hessx(j,i) + term(1,j)
c                           hessy(j,i) = hessy(j,i) + term(2,j)
c                           hessz(j,i) = hessz(j,i) + term(3,j)
c                           hessx(j,k) = hessx(j,k) - term(1,j)
c                           hessy(j,k) = hessy(j,k) - term(2,j)
c                           hessz(j,k) = hessz(j,k) - term(3,j)
c                        end do
c                     else if (k .eq. kv) then
c                        do j = 1, 3
c                           hessx(j,i) = hessx(j,i) + term(1,j)*redi2
c                           hessy(j,i) = hessy(j,i) + term(2,j)*redi2
c                           hessz(j,i) = hessz(j,i) + term(3,j)*redi2
c                           hessx(j,k) = hessx(j,k) - term(1,j)*redi
c                           hessy(j,k) = hessy(j,k) - term(2,j)*redi
c                           hessz(j,k) = hessz(j,k) - term(3,j)*redi
c                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediiv
c                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediiv
c                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediiv
c                        end do
c                     else if (i .eq. iv) then
c                        redk = kred(k)
c                        redkv = 1.0d0 - redk
c                        do j = 1, 3
c                           hessx(j,i) = hessx(j,i) + term(1,j)
c                           hessy(j,i) = hessy(j,i) + term(2,j)
c                           hessz(j,i) = hessz(j,i) + term(3,j)
c                           hessx(j,k) = hessx(j,k) - term(1,j)*redk
c                           hessy(j,k) = hessy(j,k) - term(2,j)*redk
c                           hessz(j,k) = hessz(j,k) - term(3,j)*redk
c                           hessx(j,kv) = hessx(j,kv) - term(1,j)*redkv
c                           hessy(j,kv) = hessy(j,kv) - term(2,j)*redkv
c                           hessz(j,kv) = hessz(j,kv) - term(3,j)*redkv
c                        end do
c                     else
c                        redk = kred(k)
c                        redkv = 1.0d0 - redk
c                        redik = redi * redk
c                        redikv = redi * redkv
c                        do j = 1, 3
c                           hessx(j,i) = hessx(j,i) + term(1,j)*redi2
c                           hessy(j,i) = hessy(j,i) + term(2,j)*redi2
c                           hessz(j,i) = hessz(j,i) + term(3,j)*redi2
c                           hessx(j,k) = hessx(j,k) - term(1,j)*redik
c                           hessy(j,k) = hessy(j,k) - term(2,j)*redik
c                           hessz(j,k) = hessz(j,k) - term(3,j)*redik
c                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediiv
c                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediiv
c                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediiv
c                           hessx(j,kv) = hessx(j,kv) - term(1,j)*redikv
c                           hessy(j,kv) = hessy(j,kv) - term(2,j)*redikv
c                           hessz(j,kv) = hessz(j,kv) - term(3,j)*redikv
c                        end do
c                     end if
c                  else if (iv .eq. iatom) then
c                     if (k .eq. kv) then
c                        do j = 1, 3
c                           hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
c                           hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
c                           hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
c                           hessx(j,k) = hessx(j,k) - term(1,j)*rediv
c                           hessy(j,k) = hessy(j,k) - term(2,j)*rediv
c                           hessz(j,k) = hessz(j,k) - term(3,j)*rediv
c                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediv2
c                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediv2
c                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediv2
c                        end do
c                     else
c                        redk = kred(k)
c                        redkv = 1.0d0 - redk
c                        redivk = rediv * redk
c                        redivkv = rediv * redkv
c                        do j = 1, 3
c                           hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
c                           hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
c                           hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
c                           hessx(j,k) = hessx(j,k) - term(1,j)*redivk
c                           hessy(j,k) = hessy(j,k) - term(2,j)*redivk
c                           hessz(j,k) = hessz(j,k) - term(3,j)*redivk
c                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediv2
c                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediv2
c                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediv2
c                           hessx(j,kv) = hessx(j,kv) - term(1,j)*redivkv
c                           hessy(j,kv) = hessy(j,kv) - term(2,j)*redivkv
c                           hessz(j,kv) = hessz(j,kv) - term(3,j)*redivkv
c                        end do
c                     end if
c                  end if
c               end if
c            end if
c         end do
cc
cc     reset interaction scaling coefficients for connected atoms
cc
c         do j = 1, n12(i)
c            vscale(i12(j,i)) = 1.0d0
c         end do
c         do j = 1, n13(i)
c            vscale(i13(j,i)) = 1.0d0
c         end do
c         do j = 1, n14(i)
c            vscale(i14(j,i)) = 1.0d0
c         end do
c         do j = 1, n15(i)
c            vscale(i15(j,i)) = 1.0d0
c         end do
c      end do
cc
cc     for periodic boundary conditions with large cutoffs
cc     neighbors must be found by the replicates method
cc
c      if (.not. use_replica)  return
cc
cc     calculate interaction energy with other unit cells
cc
c      do ii = 1, nlist
c         i = list(ii)
c         iv = ired(i)
c         redi = kred(i)
c         if (i .ne. iv) then
c            rediv = 1.0d0 - redi
c            redi2 = redi * redi
c            rediv2 = rediv * rediv
c            rediiv = redi * rediv
c         end if
c         it = jvdw(i)
c         xi = xred(i)
c         yi = yred(i)
c         zi = zred(i)
cc
cc     set interaction scaling coefficients for connected atoms
cc
c         do j = 1, n12(i)
c            vscale(i12(j,i)) = v2scale
c         end do
c         do j = 1, n13(i)
c            vscale(i13(j,i)) = v3scale
c         end do
c         do j = 1, n14(i)
c            vscale(i14(j,i)) = v4scale
c            iv14(i14(j,i)) = i
c         end do
c         do j = 1, n15(i)
c            vscale(i15(j,i)) = v5scale
c         end do
cc
cc     decide whether to compute the current interaction
cc
c         do kk = 1, nvdw
c            k = ivdw(kk)
c            kv = ired(k)
c            proceed = .true.
c            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
cc
cc     compute the Hessian elements for this interaction
cc
c            if (proceed) then
c               kt = jvdw(k)
c               do jcell = 1, ncell
c                  xr = xi - xred(k)
c                  yr = yi - yred(k)
c                  zr = zi - zred(k)
c                  call imager (xr,yr,zr,jcell)
c                  rik2 = xr*xr + yr*yr + zr*zr
cc
cc     check for an interaction distance less than the cutoff
cc
c                  if (rik2 .le. off2) then
c                     rv = radmin(kt,it)
c                     eps = epsilon(kt,it)
c                     if (use_polymer) then
c                        if (rik2 .le. polycut2) then
c                           if (iv14(k) .eq. i) then
c                              rv = radmin4(kt,it)
c                              eps = epsilon4(kt,it)
c                           end if
c                           eps = eps * vscale(k)
c                        end if
c                     end if
c                     rik = sqrt(rik2)
c                     p6 = rv**6 / rik2**3
c                     p12 = p6 * p6
c                     de = eps * (p12-p6) * (-12.0d0/rik)
c                     d2e = eps * (13.0d0*p12-7.0d0*p6) * (12.0d0/rik2)
cc
cc     use energy switching if near the cutoff distance
cc
c                     if (rik2 .gt. cut2) then
c                        e = eps * (p12-2.0d0*p6)
c                        rik3 = rik2 * rik
c                        rik4 = rik2 * rik2
c                        rik5 = rik2 * rik3
c                        taper = c5*rik5 + c4*rik4 + c3*rik3
c     &                             + c2*rik2 + c1*rik + c0
c                        dtaper = 5.0d0*c5*rik4 + 4.0d0*c4*rik3
c     &                           + 3.0d0*c3*rik2 + 2.0d0*c2*rik + c1
c                        d2taper = 20.0d0*c5*rik3 + 12.0d0*c4*rik2
c     &                             + 6.0d0*c3*rik + 2.0d0*c2
c                        d2e = e*d2taper + 2.0d0*de*dtaper + d2e*taper
c                        de = e*dtaper + de*taper
c                     end if
cc
cc     scale the interaction based on its group membership
cc
c                     if (use_group) then
c                        de = de * fgrp
c                        d2e = d2e * fgrp
c                     end if
cc
cc     get chain rule terms for van der Waals Hessian elements
cc
c                     de = de / rik
c                     d2e = (d2e-de) / rik2
c                     d2edx = d2e * xr
c                     d2edy = d2e * yr
c                     d2edz = d2e * zr
c                     term(1,1) = d2edx*xr + de
c                     term(1,2) = d2edx*yr
c                     term(1,3) = d2edx*zr
c                     term(2,1) = term(1,2)
c                     term(2,2) = d2edy*yr + de
c                     term(2,3) = d2edy*zr
c                     term(3,1) = term(1,3)
c                     term(3,2) = term(2,3)
c                     term(3,3) = d2edz*zr + de
cc
cc     increment diagonal and non-diagonal Hessian elements
cc
c                     if (i .eq. iatom) then
c                        if (i.eq.iv .and. k.eq.kv) then
c                           do j = 1, 3
c                              hessx(j,i) = hessx(j,i) + term(1,j)
c                              hessy(j,i) = hessy(j,i) + term(2,j)
c                              hessz(j,i) = hessz(j,i) + term(3,j)
c                              hessx(j,k) = hessx(j,k) - term(1,j)
c                              hessy(j,k) = hessy(j,k) - term(2,j)
c                              hessz(j,k) = hessz(j,k) - term(3,j)
c                           end do
c                        else if (k .eq. kv) then
c                           do j = 1, 3
c                              hessx(j,i) = hessx(j,i) + term(1,j)*redi2
c                              hessy(j,i) = hessy(j,i) + term(2,j)*redi2
c                              hessz(j,i) = hessz(j,i) + term(3,j)*redi2
c                              hessx(j,k) = hessx(j,k) - term(1,j)*redi
c                              hessy(j,k) = hessy(j,k) - term(2,j)*redi
c                              hessz(j,k) = hessz(j,k) - term(3,j)*redi
c                              hessx(j,iv) = hessx(j,iv)
c     &                                         + term(1,j)*rediiv
c                              hessy(j,iv) = hessy(j,iv)
c     &                                         + term(2,j)*rediiv
c                              hessz(j,iv) = hessz(j,iv)
c     &                                         + term(3,j)*rediiv
c                           end do
c                        else if (i .eq. iv) then
c                           redk = kred(k)
c                           redkv = 1.0d0 - redk
c                           do j = 1, 3
c                              hessx(j,i) = hessx(j,i) + term(1,j)
c                              hessy(j,i) = hessy(j,i) + term(2,j)
c                              hessz(j,i) = hessz(j,i) + term(3,j)
c                              hessx(j,k) = hessx(j,k) - term(1,j)*redk
c                              hessy(j,k) = hessy(j,k) - term(2,j)*redk
c                              hessz(j,k) = hessz(j,k) - term(3,j)*redk
c                              hessx(j,kv) = hessx(j,kv)
c     &                                         - term(1,j)*redkv
c                              hessy(j,kv) = hessy(j,kv)
c     &                                         - term(2,j)*redkv
c                              hessz(j,kv) = hessz(j,kv)
c     &                                         - term(3,j)*redkv
c                           end do
c                        else
c                           redk = kred(k)
c                           redkv = 1.0d0 - redk
c                           redik = redi * redk
c                           redikv = redi * redkv
c                           do j = 1, 3
c                              hessx(j,i) = hessx(j,i) + term(1,j)*redi2
c                              hessy(j,i) = hessy(j,i) + term(2,j)*redi2
c                              hessz(j,i) = hessz(j,i) + term(3,j)*redi2
c                              hessx(j,k) = hessx(j,k) - term(1,j)*redik
c                              hessy(j,k) = hessy(j,k) - term(2,j)*redik
c                              hessz(j,k) = hessz(j,k) - term(3,j)*redik
c                              hessx(j,iv) = hessx(j,iv)
c     &                                         + term(1,j)*rediiv
c                              hessy(j,iv) = hessy(j,iv)
c     &                                         + term(2,j)*rediiv
c                              hessz(j,iv) = hessz(j,iv)
c     &                                         + term(3,j)*rediiv
c                              hessx(j,kv) = hessx(j,kv)
c     &                                         - term(1,j)*redikv
c                              hessy(j,kv) = hessy(j,kv)
c     &                                         - term(2,j)*redikv
c                              hessz(j,kv) = hessz(j,kv)
c     &                                         - term(3,j)*redikv
c                           end do
c                        end if
c                     else if (iv .eq. iatom) then
c                        if (k .eq. kv) then
c                           do j = 1, 3
c                              hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
c                              hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
c                              hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
c                              hessx(j,k) = hessx(j,k) - term(1,j)*rediv
c                              hessy(j,k) = hessy(j,k) - term(2,j)*rediv
c                              hessz(j,k) = hessz(j,k) - term(3,j)*rediv
c                              hessx(j,iv) = hessx(j,iv)
c     &                                         + term(1,j)*rediv2
c                              hessy(j,iv) = hessy(j,iv)
c     &                                         + term(2,j)*rediv2
c                              hessz(j,iv) = hessz(j,iv)
c     &                                         + term(3,j)*rediv2
c                           end do
c                        else
c                           redk = kred(k)
c                           redkv = 1.0d0 - redk
c                           redivk = rediv * redk
c                           redivkv = rediv * redkv
c                           do j = 1, 3
c                              hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
c                              hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
c                              hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
c                              hessx(j,k) = hessx(j,k) - term(1,j)*redivk
c                              hessy(j,k) = hessy(j,k) - term(2,j)*redivk
c                              hessz(j,k) = hessz(j,k) - term(3,j)*redivk
c                              hessx(j,iv) = hessx(j,iv)
c     &                                         + term(1,j)*rediv2
c                              hessy(j,iv) = hessy(j,iv)
c     &                                         + term(2,j)*rediv2
c                              hessz(j,iv) = hessz(j,iv)
c     &                                         + term(3,j)*rediv2
c                              hessx(j,kv) = hessx(j,kv)
c     &                                         - term(1,j)*redivkv
c                              hessy(j,kv) = hessy(j,kv)
c     &                                         - term(2,j)*redivkv
c                              hessz(j,kv) = hessz(j,kv)
c     &                                         - term(3,j)*redivkv
c                           end do
c                        end if
c                     end if
c                  end if
c               end do
c            end if
c         end do
cc
cc     reset interaction scaling coefficients for connected atoms
cc
c         do j = 1, n12(i)
c            vscale(i12(j,i)) = 1.0d0
c         end do
c         do j = 1, n13(i)
c            vscale(i13(j,i)) = 1.0d0
c         end do
c         do j = 1, n14(i)
c            vscale(i14(j,i)) = 1.0d0
c         end do
c         do j = 1, n15(i)
c            vscale(i15(j,i)) = 1.0d0
c         end do
c      end do
cc
cc     perform deallocation of some local arrays
cc
c      deallocate (iv14)
c      deallocate (vscale)
c      return
c      end

c
c
c     ###############################################################   
c     ##                                                           ##
c     ##  subroutine elj2a  --  double loop Lennard-Jones Hessian  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "elj2a" calculates the Lennard-Jones 6-12 van der Waals second
c     derivatives using a double loop over relevant atom pairs
c
c
      subroutine elj2a (iatom,xred,yred,zred)
      use sizes
      use atomid
      use atoms
      use bound
      use cell
      use couple
      use group
      use hessn
      use shunt
      use vdw
      use vdwpot
      implicit none
      integer i,j,k
      integer ii,iv,it
      integer kk,kv,kt
      integer iatom,jcell
      integer nlist,list(5)
      integer, allocatable :: iv14(:)
      real*8 e,de,d2e,fgrp
      real*8 p6,p12,eps,rv
      real*8 xi,yi,zi
      real*8 xr,yr,zr
      real*8 redi,rediv
      real*8 redk,redkv
      real*8 redi2,rediv2
      real*8 rediiv
      real*8 redik,redivk
      real*8 redikv,redivkv
      real*8 rik,rik2,rik3
      real*8 rik4,rik5
      real*8 taper,dtaper
      real*8 d2taper
      real*8 d2edx,d2edy,d2edz
      real*8 term(3,3)
      real*8 xred(*)
      real*8 yred(*)
      real*8 zred(*)
      real*8, allocatable :: vscale(:)
      logical proceed
      character*6 mode
c
c
c     perform dynamic allocation of some local arrays
c
      allocate (iv14(n))
      allocate (vscale(n))
c
c     set arrays needed to scale connected atom interactions
c
      do i = 1, n
         vscale(i) = 1.0d0
         iv14(i) = 0
      end do
c
c     set the coefficients for the switching function
c
      mode = 'VDW'
      call switch (mode)
c
c     check to see if the atom of interest is a vdw site
c
      nlist = 0
      do k = 1, nvdw
         if (ivdw(k) .eq. iatom) then
            nlist = nlist + 1
            list(nlist) = iatom
            goto 10
         end if
      end do
      return
   10 continue
c
c     determine the atoms involved via reduction factors
c
      nlist = 1
      list(nlist) = iatom
      do k = 1, n12(iatom)
         i = i12(k,iatom)
         if (ired(i) .eq. iatom) then
            nlist = nlist + 1
            list(nlist) = i
         end if
      end do
c
c     find van der Waals Hessian elements for involved atoms
c
      do ii = 1, nlist
         i = list(ii)
         iv = ired(i)
         redi = kred(i)
         if (i .ne. iv) then
            rediv = 1.0d0 - redi
            redi2 = redi * redi
            rediv2 = rediv * rediv
            rediiv = redi * rediv
         end if
         it = jvdw(i)
         xi = xred(i)
         yi = yred(i)
         zi = zred(i)
c
c     set interaction scaling coefficients for connected atoms
c
         do j = 1, n12(i)
            vscale(i12(j,i)) = v2scale
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = v3scale
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = v4scale
            iv14(i14(j,i)) = i
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = v5scale
         end do
c
c     decide whether to compute the current interaction
c
         do kk = 1, nvdw
            k = ivdw(kk)
            kv = ired(k)
            proceed = .true.
            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
            if (proceed)  proceed = (k .ne. i)
c
c     compute the Hessian elements for this interaction
c
            if (proceed) then
               kt = jvdw(k)
               xr = xi - xred(k)
               yr = yi - yred(k)
               zr = zi - zred(k)
               call image (xr,yr,zr)
               rik2 = xr*xr + yr*yr + zr*zr
c
c     check for an interaction distance less than the cutoff
c
               if (rik2 .le. off2) then
                  rv = radmin(kt,it)
                  eps = epsilon(kt,it)
                  if (iv14(k) .eq. i) then
                     rv = radmin4(kt,it)
                     eps = epsilon4(kt,it)
                  end if
                  eps = eps * vscale(k)
                  rik = sqrt(rik2)
                  p6 = rv**6 / rik2**3
                  p12 = p6 * p6
                  de = eps * (p12-p6) * (-12.0d0/rik)
                  d2e = eps * (13.0d0*p12-7.0d0*p6) * (12.0d0/rik2)
c
c     use energy switching if near the cutoff distance
c
                  if (rik2 .gt. cut2) then
                     e = eps * (p12-2.0d0*p6)
                     rik3 = rik2 * rik
                     rik4 = rik2 * rik2
                     rik5 = rik2 * rik3
                     taper = c5*rik5 + c4*rik4 + c3*rik3
     &                          + c2*rik2 + c1*rik + c0
                     dtaper = 5.0d0*c5*rik4 + 4.0d0*c4*rik3
     &                           + 3.0d0*c3*rik2 + 2.0d0*c2*rik + c1
                     d2taper = 20.0d0*c5*rik3 + 12.0d0*c4*rik2
     &                            + 6.0d0*c3*rik + 2.0d0*c2
                     d2e = e*d2taper + 2.0d0*de*dtaper + d2e*taper
                     de = e*dtaper + de*taper
                  end if
c
c     scale the interaction based on its group membership
c
                  if (use_group) then
                     de = de * fgrp
                     d2e = d2e * fgrp
                  end if
c
c     get chain rule terms for van der Waals Hessian elements
c
                  de = de / rik
                  d2e = (d2e-de) / rik2
                  d2edx = d2e * xr
                  d2edy = d2e * yr
                  d2edz = d2e * zr
                  term(1,1) = d2edx*xr + de
                  term(1,2) = d2edx*yr
                  term(1,3) = d2edx*zr
                  term(2,1) = term(1,2)
                  term(2,2) = d2edy*yr + de
                  term(2,3) = d2edy*zr
                  term(3,1) = term(1,3)
                  term(3,2) = term(2,3)
                  term(3,3) = d2edz*zr + de
c
c     increment diagonal and non-diagonal Hessian elements
c
                  if (i .eq. iatom) then
                     if (i.eq.iv .and. k.eq.kv) then
                        do j = 1, 3
                           hessx(j,i) = hessx(j,i) + term(1,j)
                           hessy(j,i) = hessy(j,i) + term(2,j)
                           hessz(j,i) = hessz(j,i) + term(3,j)
                           hessx(j,k) = hessx(j,k) - term(1,j)
                           hessy(j,k) = hessy(j,k) - term(2,j)
                           hessz(j,k) = hessz(j,k) - term(3,j)
                        end do
                     else if (k .eq. kv) then
                        do j = 1, 3
                           hessx(j,i) = hessx(j,i) + term(1,j)*redi2
                           hessy(j,i) = hessy(j,i) + term(2,j)*redi2
                           hessz(j,i) = hessz(j,i) + term(3,j)*redi2
                           hessx(j,k) = hessx(j,k) - term(1,j)*redi
                           hessy(j,k) = hessy(j,k) - term(2,j)*redi
                           hessz(j,k) = hessz(j,k) - term(3,j)*redi
                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediiv
                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediiv
                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediiv
                        end do
                     else if (i .eq. iv) then
                        redk = kred(k)
                        redkv = 1.0d0 - redk
                        do j = 1, 3
                           hessx(j,i) = hessx(j,i) + term(1,j)
                           hessy(j,i) = hessy(j,i) + term(2,j)
                           hessz(j,i) = hessz(j,i) + term(3,j)
                           hessx(j,k) = hessx(j,k) - term(1,j)*redk
                           hessy(j,k) = hessy(j,k) - term(2,j)*redk
                           hessz(j,k) = hessz(j,k) - term(3,j)*redk
                           hessx(j,kv) = hessx(j,kv) - term(1,j)*redkv
                           hessy(j,kv) = hessy(j,kv) - term(2,j)*redkv
                           hessz(j,kv) = hessz(j,kv) - term(3,j)*redkv
                        end do
                     else
                        redk = kred(k)
                        redkv = 1.0d0 - redk
                        redik = redi * redk
                        redikv = redi * redkv
                        do j = 1, 3
                           hessx(j,i) = hessx(j,i) + term(1,j)*redi2
                           hessy(j,i) = hessy(j,i) + term(2,j)*redi2
                           hessz(j,i) = hessz(j,i) + term(3,j)*redi2
                           hessx(j,k) = hessx(j,k) - term(1,j)*redik
                           hessy(j,k) = hessy(j,k) - term(2,j)*redik
                           hessz(j,k) = hessz(j,k) - term(3,j)*redik
                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediiv
                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediiv
                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediiv
                           hessx(j,kv) = hessx(j,kv) - term(1,j)*redikv
                           hessy(j,kv) = hessy(j,kv) - term(2,j)*redikv
                           hessz(j,kv) = hessz(j,kv) - term(3,j)*redikv
                        end do
                     end if
                  else if (iv .eq. iatom) then
                     if (k .eq. kv) then
                        do j = 1, 3
                           hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
                           hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
                           hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
                           hessx(j,k) = hessx(j,k) - term(1,j)*rediv
                           hessy(j,k) = hessy(j,k) - term(2,j)*rediv
                           hessz(j,k) = hessz(j,k) - term(3,j)*rediv
                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediv2
                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediv2
                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediv2
                        end do
                     else
                        redk = kred(k)
                        redkv = 1.0d0 - redk
                        redivk = rediv * redk
                        redivkv = rediv * redkv
                        do j = 1, 3
                           hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
                           hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
                           hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
                           hessx(j,k) = hessx(j,k) - term(1,j)*redivk
                           hessy(j,k) = hessy(j,k) - term(2,j)*redivk
                           hessz(j,k) = hessz(j,k) - term(3,j)*redivk
                           hessx(j,iv) = hessx(j,iv) + term(1,j)*rediv2
                           hessy(j,iv) = hessy(j,iv) + term(2,j)*rediv2
                           hessz(j,iv) = hessz(j,iv) + term(3,j)*rediv2
                           hessx(j,kv) = hessx(j,kv) - term(1,j)*redivkv
                           hessy(j,kv) = hessy(j,kv) - term(2,j)*redivkv
                           hessz(j,kv) = hessz(j,kv) - term(3,j)*redivkv
                        end do
                     end if
                  end if
               end if
            end if
         end do
c
c     reset interaction scaling coefficients for connected atoms
c
         do j = 1, n12(i)
            vscale(i12(j,i)) = 1.0d0
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = 1.0d0
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = 1.0d0
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = 1.0d0
         end do
      end do
c
c     for periodic boundary conditions with large cutoffs
c     neighbors must be found by the replicates method
c
      if (.not. use_replica)  return
c
c     calculate interaction energy with other unit cells
c
      do ii = 1, nlist
         i = list(ii)
         iv = ired(i)
         redi = kred(i)
         if (i .ne. iv) then
            rediv = 1.0d0 - redi
            redi2 = redi * redi
            rediv2 = rediv * rediv
            rediiv = redi * rediv
         end if
         it = jvdw(i)
         xi = xred(i)
         yi = yred(i)
         zi = zred(i)
c
c     set interaction scaling coefficients for connected atoms
c
         do j = 1, n12(i)
            vscale(i12(j,i)) = v2scale
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = v3scale
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = v4scale
            iv14(i14(j,i)) = i
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = v5scale
         end do
c
c     decide whether to compute the current interaction
c
         do kk = 1, nvdw
            k = ivdw(kk)
            kv = ired(k)
            proceed = .true.
            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
c
c     compute the Hessian elements for this interaction
c
            if (proceed) then
               kt = jvdw(k)
               do jcell = 1, ncell
                  xr = xi - xred(k)
                  yr = yi - yred(k)
                  zr = zi - zred(k)
                  call imager (xr,yr,zr,jcell)
                  rik2 = xr*xr + yr*yr + zr*zr
c
c     check for an interaction distance less than the cutoff
c
                  if (rik2 .le. off2) then
                     rv = radmin(kt,it)
                     eps = epsilon(kt,it)
                     if (use_polymer) then
                        if (rik2 .le. polycut2) then
                           if (iv14(k) .eq. i) then
                              rv = radmin4(kt,it)
                              eps = epsilon4(kt,it)
                           end if
                           eps = eps * vscale(k)
                        end if
                     end if
                     rik = sqrt(rik2)
                     p6 = rv**6 / rik2**3
                     p12 = p6 * p6
                     de = eps * (p12-p6) * (-12.0d0/rik)
                     d2e = eps * (13.0d0*p12-7.0d0*p6) * (12.0d0/rik2)
c
c     use energy switching if near the cutoff distance
c
                     if (rik2 .gt. cut2) then
                        e = eps * (p12-2.0d0*p6)
                        rik3 = rik2 * rik
                        rik4 = rik2 * rik2
                        rik5 = rik2 * rik3
                        taper = c5*rik5 + c4*rik4 + c3*rik3
     &                             + c2*rik2 + c1*rik + c0
                        dtaper = 5.0d0*c5*rik4 + 4.0d0*c4*rik3
     &                           + 3.0d0*c3*rik2 + 2.0d0*c2*rik + c1
                        d2taper = 20.0d0*c5*rik3 + 12.0d0*c4*rik2
     &                             + 6.0d0*c3*rik + 2.0d0*c2
                        d2e = e*d2taper + 2.0d0*de*dtaper + d2e*taper
                        de = e*dtaper + de*taper
                     end if
c
c     scale the interaction based on its group membership
c
                     if (use_group) then
                        de = de * fgrp
                        d2e = d2e * fgrp
                     end if
c
c     get chain rule terms for van der Waals Hessian elements
c
                     de = de / rik
                     d2e = (d2e-de) / rik2
                     d2edx = d2e * xr
                     d2edy = d2e * yr
                     d2edz = d2e * zr
                     term(1,1) = d2edx*xr + de
                     term(1,2) = d2edx*yr
                     term(1,3) = d2edx*zr
                     term(2,1) = term(1,2)
                     term(2,2) = d2edy*yr + de
                     term(2,3) = d2edy*zr
                     term(3,1) = term(1,3)
                     term(3,2) = term(2,3)
                     term(3,3) = d2edz*zr + de
c
c     increment diagonal and non-diagonal Hessian elements
c
                     if (i .eq. iatom) then
                        if (i.eq.iv .and. k.eq.kv) then
                           do j = 1, 3
                              hessx(j,i) = hessx(j,i) + term(1,j)
                              hessy(j,i) = hessy(j,i) + term(2,j)
                              hessz(j,i) = hessz(j,i) + term(3,j)
                              hessx(j,k) = hessx(j,k) - term(1,j)
                              hessy(j,k) = hessy(j,k) - term(2,j)
                              hessz(j,k) = hessz(j,k) - term(3,j)
                           end do
                        else if (k .eq. kv) then
                           do j = 1, 3
                              hessx(j,i) = hessx(j,i) + term(1,j)*redi2
                              hessy(j,i) = hessy(j,i) + term(2,j)*redi2
                              hessz(j,i) = hessz(j,i) + term(3,j)*redi2
                              hessx(j,k) = hessx(j,k) - term(1,j)*redi
                              hessy(j,k) = hessy(j,k) - term(2,j)*redi
                              hessz(j,k) = hessz(j,k) - term(3,j)*redi
                              hessx(j,iv) = hessx(j,iv)
     &                                         + term(1,j)*rediiv
                              hessy(j,iv) = hessy(j,iv)
     &                                         + term(2,j)*rediiv
                              hessz(j,iv) = hessz(j,iv)
     &                                         + term(3,j)*rediiv
                           end do
                        else if (i .eq. iv) then
                           redk = kred(k)
                           redkv = 1.0d0 - redk
                           do j = 1, 3
                              hessx(j,i) = hessx(j,i) + term(1,j)
                              hessy(j,i) = hessy(j,i) + term(2,j)
                              hessz(j,i) = hessz(j,i) + term(3,j)
                              hessx(j,k) = hessx(j,k) - term(1,j)*redk
                              hessy(j,k) = hessy(j,k) - term(2,j)*redk
                              hessz(j,k) = hessz(j,k) - term(3,j)*redk
                              hessx(j,kv) = hessx(j,kv)
     &                                         - term(1,j)*redkv
                              hessy(j,kv) = hessy(j,kv)
     &                                         - term(2,j)*redkv
                              hessz(j,kv) = hessz(j,kv)
     &                                         - term(3,j)*redkv
                           end do
                        else
                           redk = kred(k)
                           redkv = 1.0d0 - redk
                           redik = redi * redk
                           redikv = redi * redkv
                           do j = 1, 3
                              hessx(j,i) = hessx(j,i) + term(1,j)*redi2
                              hessy(j,i) = hessy(j,i) + term(2,j)*redi2
                              hessz(j,i) = hessz(j,i) + term(3,j)*redi2
                              hessx(j,k) = hessx(j,k) - term(1,j)*redik
                              hessy(j,k) = hessy(j,k) - term(2,j)*redik
                              hessz(j,k) = hessz(j,k) - term(3,j)*redik
                              hessx(j,iv) = hessx(j,iv)
     &                                         + term(1,j)*rediiv
                              hessy(j,iv) = hessy(j,iv)
     &                                         + term(2,j)*rediiv
                              hessz(j,iv) = hessz(j,iv)
     &                                         + term(3,j)*rediiv
                              hessx(j,kv) = hessx(j,kv)
     &                                         - term(1,j)*redikv
                              hessy(j,kv) = hessy(j,kv)
     &                                         - term(2,j)*redikv
                              hessz(j,kv) = hessz(j,kv)
     &                                         - term(3,j)*redikv
                           end do
                        end if
                     else if (iv .eq. iatom) then
                        if (k .eq. kv) then
                           do j = 1, 3
                              hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
                              hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
                              hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
                              hessx(j,k) = hessx(j,k) - term(1,j)*rediv
                              hessy(j,k) = hessy(j,k) - term(2,j)*rediv
                              hessz(j,k) = hessz(j,k) - term(3,j)*rediv
                              hessx(j,iv) = hessx(j,iv)
     &                                         + term(1,j)*rediv2
                              hessy(j,iv) = hessy(j,iv)
     &                                         + term(2,j)*rediv2
                              hessz(j,iv) = hessz(j,iv)
     &                                         + term(3,j)*rediv2
                           end do
                        else
                           redk = kred(k)
                           redkv = 1.0d0 - redk
                           redivk = rediv * redk
                           redivkv = rediv * redkv
                           do j = 1, 3
                              hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
                              hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
                              hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
                              hessx(j,k) = hessx(j,k) - term(1,j)*redivk
                              hessy(j,k) = hessy(j,k) - term(2,j)*redivk
                              hessz(j,k) = hessz(j,k) - term(3,j)*redivk
                              hessx(j,iv) = hessx(j,iv)
     &                                         + term(1,j)*rediv2
                              hessy(j,iv) = hessy(j,iv)
     &                                         + term(2,j)*rediv2
                              hessz(j,iv) = hessz(j,iv)
     &                                         + term(3,j)*rediv2
                              hessx(j,kv) = hessx(j,kv)
     &                                         - term(1,j)*redivkv
                              hessy(j,kv) = hessy(j,kv)
     &                                         - term(2,j)*redivkv
                              hessz(j,kv) = hessz(j,kv)
     &                                         - term(3,j)*redivkv
                           end do
                        end if
                     end if
                  end if
               end do
            end if
         end do
c
c     reset interaction scaling coefficients for connected atoms
c
         do j = 1, n12(i)
            vscale(i12(j,i)) = 1.0d0
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = 1.0d0
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = 1.0d0
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = 1.0d0
         end do
      end do
c
c     perform deallocation of some local arrays
c
      deallocate (iv14)
      deallocate (vscale)
      return
      end
c
c
c     #################################################################
c     ##                                                             ##
c     ##  subroutine elj2b  --  Lennard-Jones Hessian for smoothing  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "elj2b" calculates the Lennard-Jones 6-12 van der Waals second
c     derivatives via a Gaussian approximation for use with potential
c     energy smoothing
c
c
      subroutine elj2b (i,xred,yred,zred)
      use sizes
      use math
      use vdwpot
      implicit none
      integer i
      real*8 xred(*)
      real*8 yred(*)
      real*8 zred(*)
c
c
c     set coefficients for a two-Gaussian fit to Lennard-Jones
c
      ngauss = 2
      igauss(1,1) = 14487.1d0
      igauss(2,1) = 9.05148d0 * twosix**2
      igauss(1,2) = -5.55338d0
      igauss(2,2) = 1.22536d0 * twosix**2
c
c     compute Gaussian approximation to Lennard-Jones potential
c
      call egauss2 (i,xred,yred,zred)
      return
      end
c
c
c     ###############################################################
c     ##                                                           ##
c     ##  subroutine elj2c  --  Lennard-Jones Hessian for stophat  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "elj2c" calculates the Lennard-Jones 6-12 van der Waals second
c     derivatives for use with stophat potential energy smoothing
c
c
      subroutine elj2c (iatom,xred,yred,zred)
      use sizes
      use atomid
      use atoms
      use couple
      use group
      use hessn
      use vdw
      use vdwpot
      use warp
      implicit none
      integer i,j,k,iatom
      integer ii,iv,it
      integer kk,kv,kt
      integer nlist,list(5)
      integer, allocatable :: iv14(:)
      real*8 de,d2e
      real*8 p6,denom
      real*8 eps,rv,fgrp
      real*8 xi,yi,zi
      real*8 xr,yr,zr
      real*8 redi,rediv
      real*8 redk,redkv
      real*8 redi2,rediv2
      real*8 rediiv
      real*8 redik,redivk
      real*8 redikv,redivkv
      real*8 rik,rik2
      real*8 rik3,rik4
      real*8 rik5,rik6
      real*8 rik7,rik8
      real*8 width,width2
      real*8 width3,width4
      real*8 width5,width6
      real*8 width7,width8
      real*8 d2edx,d2edy,d2edz
      real*8 term(3,3)
      real*8 xred(*)
      real*8 yred(*)
      real*8 zred(*)
      real*8, allocatable :: vscale(:)
      logical proceed
c
c
c     perform dynamic allocation of some local arrays
c
      allocate (iv14(n))
      allocate (vscale(n))
c
c     set arrays needed to scale connected atom interactions
c
      do i = 1, n
         vscale(i) = 1.0d0
         iv14(i) = 0
      end do
c
c     check to see if the atom of interest is a vdw site
c
      nlist = 0
      do k = 1, nvdw
         if (ivdw(k) .eq. iatom) then
            nlist = nlist + 1
            list(nlist) = iatom
            goto 10
         end if
      end do
      return
   10 continue
c
c     determine the atoms involved via reduction factors
c
      nlist = 1
      list(nlist) = iatom
      do k = 1, n12(iatom)
         i = i12(k,iatom)
         if (ired(i) .eq. iatom) then
            nlist = nlist + 1
            list(nlist) = i
         end if
      end do
c
c     set the extent of smoothing to be performed
c
      width = deform * diffv
      width2 = width * width
      width3 = width2 * width
      width4 = width2 * width2
      width5 = width2 * width3
      width6 = width3 * width3
      width7 = width3 * width4
      width8 = width4 * width4
c
c     find van der Waals Hessian elements for involved atoms
c
      do ii = 1, nlist
         i = list(ii)
         iv = ired(i)
         redi = kred(i)
         if (i .ne. iv) then
            rediv = 1.0d0 - redi
            redi2 = redi * redi
            rediv2 = rediv * rediv
            rediiv = redi * rediv
         end if
         it = jvdw(i)
         xi = xred(i)
         yi = yred(i)
         zi = zred(i)
c
c     set interaction scaling coefficients for connected atoms
c
         do j = 1, n12(i)
            vscale(i12(j,i)) = v2scale
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = v3scale
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = v4scale
            iv14(i14(j,i)) = i
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = v5scale
         end do
c
c     decide whether to compute the current interaction
c
         do kk = 1, nvdw
            k = ivdw(kk)
            kv = ired(k)
            proceed = .true.
            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
            if (proceed)  proceed = (k .ne. i)
c
c     compute the Hessian elements for this interaction
c
            if (proceed) then
               kt = jvdw(k)
               xr = xi - xred(k)
               yr = yi - yred(k)
               zr = zi - zred(k)
               rik2 = xr*xr + yr*yr + zr*zr
               rv = radmin(kt,it)
               eps = epsilon(kt,it)
               if (iv14(k) .eq. i) then
                  rv = radmin4(kt,it)
                  eps = epsilon4(kt,it)
               end if
               eps = eps * vscale(k)
               p6 = rv**6
               rik = sqrt(rik2)
               rik3 = rik2 * rik
               rik4 = rik2 * rik2
               rik5 = rik2 * rik3
               rik6 = rik3 * rik3
               rik7 = rik3 * rik4
               rik8 = rik4 * rik4
               denom = rik * (rik+2.0d0*width)
               denom = denom**10
c
c     transform the potential function via smoothing
c
               de = rik5 * (5.0d0*rik8 + 65.0d0*rik7*width
     &                 + 360.0d0*rik6*width2 + 1100.0d0*rik5*width3
     &                 + 2000.0d0*rik4*width4 + 2160.0d0*rik3*width5
     &                 + 1280.0d0*rik2*width6 + 320.0d0*rik*width7)
               de = de - p6 * (5.0d0*rik7 + 35.0d0*rik6*width
     &                 + 132.0d0*rik5*width2 + 310.0d0*rik4*width3
     &                 + 472.0d0*rik3*width4 + 456.0d0*rik2*width5
     &                 + 256.0d0*rik*width6 + 64.0d0*width7)
               de = de*eps*p6*12.0d0 / (5.0d0*denom)
               d2e = rik6 * (35.0d0*rik8 +  490.0d0*rik7*width
     &                  + 2980.0d0*rik6*width2 + 10280.0d0*rik5*width3
     &                  + 22000.0d0*rik4*width4 + 29920.0d0*rik3*width5
     &                  + 25280.0d0*rik2*width6 + 12160.0d0*rik*width7
     &                  + 2560.0d0*width8)
               d2e = d2e - p6 * (65.0d0*rik8 + 520.0d0*rik7*width
     &                  + 2260.0d0*rik6*width2 + 6280.0d0*rik5*width3
     &                  + 11744.0d0*rik4*width4 + 14816.0d0*rik3*width5
     &                  + 12160.0d0*rik2*width6 + 5888.0d0*rik*width7
     &                  + 1280.0d0*width8)
               d2e = -12.0d0*p6*eps*d2e
     &                  / (5.0d0*denom*rik*(rik+2.0d0*width))
c
c     scale the interaction based on its group membership
c
               if (use_group) then
                  de = de * fgrp
                  d2e = d2e * fgrp
               end if
c
c     get chain rule terms for van der Waals Hessian elements
c
               de = de / rik
               d2e = (d2e-de) / rik2
               d2edx = d2e * xr
               d2edy = d2e * yr
               d2edz = d2e * zr
               term(1,1) = d2edx*xr + de
               term(1,2) = d2edx*yr
               term(1,3) = d2edx*zr
               term(2,1) = term(1,2)
               term(2,2) = d2edy*yr + de
               term(2,3) = d2edy*zr
               term(3,1) = term(1,3)
               term(3,2) = term(2,3)
               term(3,3) = d2edz*zr + de
c
c     increment diagonal and non-diagonal Hessian elements
c
               if (i .eq. iatom) then
                  if (i.eq.iv .and. k.eq.kv) then
                     do j = 1, 3
                        hessx(j,i) = hessx(j,i) + term(1,j)
                        hessy(j,i) = hessy(j,i) + term(2,j)
                        hessz(j,i) = hessz(j,i) + term(3,j)
                        hessx(j,k) = hessx(j,k) - term(1,j)
                        hessy(j,k) = hessy(j,k) - term(2,j)
                        hessz(j,k) = hessz(j,k) - term(3,j)
                     end do
                  else if (k .eq. kv) then
                     do j = 1, 3
                        hessx(j,i) = hessx(j,i) + term(1,j)*redi2
                        hessy(j,i) = hessy(j,i) + term(2,j)*redi2
                        hessz(j,i) = hessz(j,i) + term(3,j)*redi2
                        hessx(j,k) = hessx(j,k) - term(1,j)*redi
                        hessy(j,k) = hessy(j,k) - term(2,j)*redi
                        hessz(j,k) = hessz(j,k) - term(3,j)*redi
                        hessx(j,iv) = hessx(j,iv) + term(1,j)*rediiv
                        hessy(j,iv) = hessy(j,iv) + term(2,j)*rediiv
                        hessz(j,iv) = hessz(j,iv) + term(3,j)*rediiv
                     end do
                  else if (i .eq. iv) then
                     redk = kred(k)
                     redkv = 1.0d0 - redk
                     do j = 1, 3
                        hessx(j,i) = hessx(j,i) + term(1,j)
                        hessy(j,i) = hessy(j,i) + term(2,j)
                        hessz(j,i) = hessz(j,i) + term(3,j)
                        hessx(j,k) = hessx(j,k) - term(1,j)*redk
                        hessy(j,k) = hessy(j,k) - term(2,j)*redk
                        hessz(j,k) = hessz(j,k) - term(3,j)*redk
                        hessx(j,kv) = hessx(j,kv) - term(1,j)*redkv
                        hessy(j,kv) = hessy(j,kv) - term(2,j)*redkv
                        hessz(j,kv) = hessz(j,kv) - term(3,j)*redkv
                     end do
                  else
                     redk = kred(k)
                     redkv = 1.0d0 - redk
                     redik = redi * redk
                     redikv = redi * redkv
                     do j = 1, 3
                        hessx(j,i) = hessx(j,i) + term(1,j)*redi2
                        hessy(j,i) = hessy(j,i) + term(2,j)*redi2
                        hessz(j,i) = hessz(j,i) + term(3,j)*redi2
                        hessx(j,k) = hessx(j,k) - term(1,j)*redik
                        hessy(j,k) = hessy(j,k) - term(2,j)*redik
                        hessz(j,k) = hessz(j,k) - term(3,j)*redik
                        hessx(j,iv) = hessx(j,iv) + term(1,j)*rediiv
                        hessy(j,iv) = hessy(j,iv) + term(2,j)*rediiv
                        hessz(j,iv) = hessz(j,iv) + term(3,j)*rediiv
                        hessx(j,kv) = hessx(j,kv) - term(1,j)*redikv
                        hessy(j,kv) = hessy(j,kv) - term(2,j)*redikv
                        hessz(j,kv) = hessz(j,kv) - term(3,j)*redikv
                     end do
                  end if
               else if (iv .eq. iatom) then
                  if (k .eq. kv) then
                     do j = 1, 3
                        hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
                        hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
                        hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
                        hessx(j,k) = hessx(j,k) - term(1,j)*rediv
                        hessy(j,k) = hessy(j,k) - term(2,j)*rediv
                        hessz(j,k) = hessz(j,k) - term(3,j)*rediv
                        hessx(j,iv) = hessx(j,iv) + term(1,j)*rediv2
                        hessy(j,iv) = hessy(j,iv) + term(2,j)*rediv2
                        hessz(j,iv) = hessz(j,iv) + term(3,j)*rediv2
                     end do
                  else
                     redk = kred(k)
                     redkv = 1.0d0 - redk
                     redivk = rediv * redk
                     redivkv = rediv * redkv
                     do j = 1, 3
                        hessx(j,i) = hessx(j,i) + term(1,j)*rediiv
                        hessy(j,i) = hessy(j,i) + term(2,j)*rediiv
                        hessz(j,i) = hessz(j,i) + term(3,j)*rediiv
                        hessx(j,k) = hessx(j,k) - term(1,j)*redivk
                        hessy(j,k) = hessy(j,k) - term(2,j)*redivk
                        hessz(j,k) = hessz(j,k) - term(3,j)*redivk
                        hessx(j,iv) = hessx(j,iv) + term(1,j)*rediv2
                        hessy(j,iv) = hessy(j,iv) + term(2,j)*rediv2
                        hessz(j,iv) = hessz(j,iv) + term(3,j)*rediv2
                        hessx(j,kv) = hessx(j,kv) - term(1,j)*redivkv
                        hessy(j,kv) = hessy(j,kv) - term(2,j)*redivkv
                        hessz(j,kv) = hessz(j,kv) - term(3,j)*redivkv
                     end do
                  end if
               end if
            end if
         end do
c
c     reset interaction scaling coefficients for connected atoms
c
         do j = 1, n12(i)
            vscale(i12(j,i)) = 1.0d0
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = 1.0d0
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = 1.0d0
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = 1.0d0
         end do
      end do
c
c     perform deallocation of some local arrays
c
      deallocate (iv14)
      deallocate (vscale)
      return
      end

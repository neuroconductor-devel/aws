C
C    Copyright (C) 2004 Weierstrass-Institut fuer 
C                       Angewandte Analysis und Stochastik (WIAS)
C
C    Author:  Joerg Polzehl
C
C  This program is free software; you can redistribute it and/or modify
C  it under the terms of the GNU General Public License as published by
C  the Free Software Foundation; either version 2 of the License, or
C  (at your option) any later version.
C
C  This program is distributed in the hope that it will be useful,
C  but WITHOUT ANY WARRANTY; without even the implied warranty of
C  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
C  GNU General Public License for more details.
C
C  You should have received a copy of the GNU General Public License
C  along with this program; if not, write to the Free Software
C  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
C  USA.
C
C  The following routines are part of the aws package and contain  
C  FORTRAN 77 code needed in R functions aws, vaws, 
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C    location penalty for multivariate non-gridded aws
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      real*8 function lmkern(kern,dx,xi,xj,h2)
      implicit logical (a-z)
      external lkern
      integer kern,dx,i
      real*8 xi(dx),xj(dx),h2,z,zd,lkern
      z=0.d0
      do 1 i=1,dx
         zd=xi(i)-xj(i)
         z=z+zd*zd
	 if(z.gt.h2) goto 2
1     continue
      lmkern=lkern(kern,z/h2)
      goto 999
2     lmkern=0.d0
999   return
      end
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C
C   Local constant aws on a grid      
C
C   this is a reimplementation of the original aws procedure
C
C   should be slightly slower for non-Gaussian models (see function kldist)
C    
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C
C          Compute the Kullback-Leibler Distance
C
C          Model=1    Gaussian   
C          Model=2    Bernoulli   
C          Model=3    Poisson   
C          Model=4    Exponential   
C
C     computing dlog(theta) and dlog(1.d0-theta) outside the AWS-loops 
C     will reduces computational costs at the price of readability
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      real*8 function kldist(model,thi,thj,bi0)
      implicit logical (a-z)
      integer model
      real*8 thi,thj,z,thij,bi0,eta,tthi
      IF (model.eq.1) THEN
C        Gaussian
         z=thi-thj
         kldist=z*z
      ELSE IF (model.eq.2) THEN
C        Bernoulli
         kldist=0.d0
         eta=0.5d0/bi0
         thij=(1.d0-eta)*thj+eta*thi
         tthi=(1.d0-thi)
         IF (thi.gt.1.d-10) kldist=kldist+thi*dlog(thi/thij)
         IF (tthi.gt.1.d-10) kldist=kldist+tthi*dlog(tthi/(1.d0-thij))
      ELSE IF (model.eq.3) THEN
C        Poisson
         kldist=0.d0
         eta=0.5d0/bi0
         thij=(1.d0-eta)*thj+eta*thi
         IF (thi.gt.1.d-10) kldist=thi*dlog(thi/thij)-thi+thij
      ELSE IF (model.eq.4) THEN
C        Exponential
         kldist=thi/thj-1.d0-dlog(thi/thj)
      ELSE IF (model.eq.5) THEN
C        Exponential
         kldist=thi/thj-1.d0-dlog(thi/thj)
      ELSE
C        use Gaussian
         z=thi-thj
         kldist=z*z
      ENDIF
      RETURN
      END
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C
C          Compute Location Kernel (Compact support only, based on x^2
C                                   ignores scaling)
C
C          Kern=1     Uniform
C          Kern=2     Epanechnicov
C          Kern=3     Biweight
C          Kern=4     Triweight
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      real*8 function lkern(kern,xsq)
      implicit logical (a-z)
      integer kern
      real*8 xsq,z
      IF (xsq.ge.1) THEN
         lkern=0.d0
      ELSE IF (kern.eq.1) THEN
         lkern=1.d0
      ELSE IF (kern.eq.2) THEN
         lkern=1.d0-xsq
      ELSE IF (kern.eq.3) THEN
         z=1.d0-xsq
         lkern=z*z
      ELSE IF (kern.eq.4) THEN
         z=1.d0-xsq
         lkern=z*z*z
      ELSE IF (kern.eq.5) THEN
         lkern=dexp(-xsq*8.d0)
      ELSE
C        use Epanechnikov
         lkern=1.d0-xsq
      ENDIF
      RETURN 
      END   
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C        Compute truncated Exponential Kernel 
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      real*8 function skern(x,xmin,xmax)
      implicit logical (a-z)
      real*8 x,xmin,xmax,spf
      spf=xmax/(xmax-xmin)
      IF (x.le.xmin) THEN
         skern=1.d0
      ELSE IF (x.gt.xmax) THEN
         skern=0.d0
      ELSE
         skern=dexp(-spf*(x-xmin))
      ENDIF
      RETURN
      END
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C   Perform one iteration in local constant three-variate aws (gridded)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      subroutine caws(y,fix,n1,n2,n3,hakt,hhom,lambda,theta,bi,bi2,
     1                bi0,ai,model,kern,spmin,lwght,wght)
C   
C   y        observed values of regression function
C   n1,n2,n3    design dimensions
C   hakt     actual bandwidth
C   lambda   lambda or lambda*sigma2 for Gaussian models
C   theta    estimates from last step   (input)
C   bi       \sum  Wi   (output)
C   ai       \sum  Wi Y     (output)
C   model    specifies the probablilistic model for the KL-Distance
C   kern     specifies the location kernel
C   wght     scaling factor for second and third dimension (larger values shrink)
C   
      implicit logical (a-z)
      external kldist,lkern
      real*8 kldist,lkern
      integer n1,n2,n3,model,kern
      logical aws,fix(1)
      real*8 y(1),theta(1),bi(1),bi0(1),ai(1),lambda,wght(2),
     1       bi2(1),hakt,lwght(1),spmin,spf,hhom(1),hhomi,hhommax
      integer ih1,ih2,ih3,i1,i2,i3,j1,j2,j3,jw1,jw2,jw3,jwind3,jwind2,
     1        iind,jind,jind3,jind2,clw1,clw2,clw3,dlw1,dlw2,dlw3
      real*8 thetai,bii,sij,swj,swj2,swj0,swjy,z1,z2,z3,wj,hakt2,bii0,
     1       hmax2
      hakt2=hakt*hakt
      spf=1.d0/(1.d0-spmin)
      ih1=hakt
      aws=lambda.lt.1d40
C
C   first calculate location weights
C
      ih3=hakt/wght(2)
      ih2=hakt/wght(1)
      ih1=hakt
      if(n3.eq.1) ih3=0
      if(n2.eq.1) ih2=0
      clw1=ih1+1
      clw2=ih2+1
      clw3=ih3+1
      dlw1=ih1+clw1
      dlw2=ih2+clw2
      dlw3=ih3+clw3
      z2=0.d0
      z3=0.d0
      DO j3=1,dlw3
         if(n3.gt.1) THEN
            z3=(clw3-j3)*wght(2)
            z3=z3*z3
            ih2=dsqrt(hakt2-z3)/wght(1)
            jind3=(j3-1)*dlw1*dlw2
	 ELSE
	    jind3=0
	 END IF
         DO j2=clw2-ih2,clw2+ih2
            if(n2.gt.1) THEN
               z2=(clw2-j2)*wght(1)
               z2=z3+z2*z2
               ih1=dsqrt(hakt2-z2)
               jind2=jind3+(j2-1)*dlw1
	    ELSE
	       jind2=0
	    END IF
            DO j1=clw1-ih1,clw1+ih1
C  first stochastic term
               jind=j1+jind2
               z1=clw1-j1
               lwght(jind)=lkern(kern,(z1*z1+z2)/hakt2)
               if(lwght(jind).gt.0.d0) hmax2=dmax1(hmax2,z2+z1*z1)
            END DO
         END DO
      END DO
      call rchkusr()
      DO i3=1,n3
         DO i2=1,n2
             DO i1=1,n1
	       iind=i1+(i2-1)*n1+(i3-1)*n1*n2
               hhomi=hhom(iind)
               hhomi=hhomi*hhomi
               hhommax=hmax2
               IF (fix(iind)) CYCLE
C    nothing to do, final estimate is already fixed by control 
               thetai=theta(iind)
               bii=bi(iind)/lambda
C   scaling of sij outside the loop
               bii0=bi0(iind)
               swj=0.d0
	       swj2=0.d0
               swj0=0.d0
               swjy=0.d0
               DO jw3=1,dlw3
	          j3=jw3-clw3+i3
	          if(j3.lt.1.or.j3.gt.n3) CYCLE
		  jwind3=(jw3-1)*dlw1*dlw2
	          jind3=(j3-1)*n1*n2
                  z3=(clw3-jw3)*wght(2)
                  z3=z3*z3
                  if(n2.gt.1) ih2=dsqrt(hakt2-z3)/wght(1)
                  DO jw2=clw2-ih2,clw2+ih2
	             j2=jw2-clw2+i2
	             if(j2.lt.1.or.j2.gt.n2) CYCLE
		     jwind2=jwind3+(jw2-1)*dlw1
	             jind2=(j2-1)*n1+jind3
                     z2=(clw2-jw2)*wght(1)
                     z2=z3+z2*z2
                     ih1=dsqrt(hakt2-z2)
                     DO jw1=clw1-ih1,clw1+ih1
C  first stochastic term
	                j1=jw1-clw1+i1
	                if(j1.lt.1.or.j1.gt.n1) CYCLE
                        jind=j1+jind2
                        wj=lwght(jw1+jwind2)
                        swj0=swj0+wj
                        z1=(clw1-jw1)
                        z1=z2+z1*z1
                        IF (aws.and.z1.ge.hhomi) THEN
                  sij=bii*kldist(model,thetai,theta(jind),bii0)
                           IF (sij.gt.1.d0) THEN
                              hhommax=dmin1(hhommax,z1)
                              CYCLE
                           END IF
			      IF (sij.gt.spmin) THEN
			         wj=wj*(1.d0-spf*(sij-spmin))
                                 hhommax=dmin1(hhommax,z1)
                              END IF
                        END IF
                        swj=swj+wj
                        swj2=swj2+wj*wj
                        swjy=swjy+wj*y(jind)
                     END DO
                  END DO
               END DO
               ai(iind)=swjy
               bi(iind)=swj
               bi2(iind)=swj2
               bi0(iind)=swj0
               hhom(iind)=dsqrt(hhommax)
               call rchkusr()
            END DO
         END DO
      END DO
      RETURN
      END
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C   Perform one iteration in local constant three-variate aws (gridded)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      subroutine caws2(y,fix,n1,n2,n3,hakt,lambda,theta,bi,bi2,
     1            bi0,ai,model,kern,spmin,lwght,wght,sdiff)
C   
C   y        observed values of regression function
C   n1,n2,n3    design dimensions
C   hakt     actual bandwidth
C   lambda   lambda or lambda*sigma2 for Gaussian models
C   theta    estimates from last step   (input)
C   bi       \sum  Wi   (output)
C   ai       \sum  Wi Y     (output)
C   model    specifies the probablilistic model for the KL-Distance
C   kern     specifies the location kernel
C   wght     scaling factor for second and third dimension (larger values shrink)
C   
      implicit logical (a-z)
      external kldist,lkern
      real*8 kldist,lkern
      integer n1,n2,n3,model,kern
      logical aws,fix(1)
      real*8 y(1),theta(1),bi(1),bi0(1),ai(1),lambda,wght(2),
     1       bi2(1),hakt,lwght(1),spmin,spf,sdiff
      integer ih1,ih2,ih3,i1,i2,i3,j1,j2,j3,jw1,jw2,jw3,jwind3,jwind2,
     1        iind,jind,jind3,jind2,clw1,clw2,clw3,dlw1,dlw2,dlw3
      real*8 thetai,bii,sij,swj,swj2,swj0,swjy,z1,z2,z3,wj,hakt2,bii0,
     1       heff,hakt2eff
      hakt2=hakt*hakt
      spf=1.d0/(1.d0-spmin)
      ih1=hakt
      aws=lambda.lt.1d40
C
C   first calculate location weights
C
      ih3=hakt/wght(2)
      ih2=hakt/wght(1)
      ih1=hakt
      if(n3.eq.1) ih3=0
      if(n2.eq.1) ih2=0
      hakt2eff=ih1*ih1/1.1604
      if(n3.eq.1) hakt2eff=ih1*ih1/1.26
      if(n2.eq.1) hakt2eff=ih1*ih1/1.57
      clw1=ih1+1
      clw2=ih2+1
      clw3=ih3+1
      dlw1=ih1+clw1
      dlw2=ih2+clw2
      dlw3=ih3+clw3
      z2=0.d0
      z3=0.d0
      DO j3=1,dlw3
         if(n3.gt.1) THEN
            z3=(clw3-j3)*wght(2)
            z3=z3*z3
            ih2=dsqrt(hakt2-z3)/wght(1)
            jind3=(j3-1)*dlw1*dlw2
	 ELSE
	    jind3=0
	 END IF
         DO j2=clw2-ih2,clw2+ih2
            if(n2.gt.1) THEN
               z2=(clw2-j2)*wght(1)
               z2=z3+z2*z2
               ih1=dsqrt(hakt2-z2)
               jind2=jind3+(j2-1)*dlw1
	    ELSE
	       jind2=0
	    END IF
            DO j1=clw1-ih1,clw1+ih1
C  first stochastic term
               jind=j1+jind2
               z1=clw1-j1
               lwght(jind)=lkern(kern,(z1*z1+z2)/hakt2)
            END DO
         END DO
      END DO
      call rchkusr()
      DO i3=1,n3
         DO i2=1,n2
             DO i1=1,n1
	       iind=i1+(i2-1)*n1+(i3-1)*n1*n2
               IF (fix(iind)) CYCLE
               heff=0.d0
C    nothing to do, final estimate is already fixed by control 
               thetai=theta(iind)
               bii=bi(iind)/lambda
C   scaling of sij outside the loop
               bii0=bi0(iind)
               swj=0.d0
	       swj2=0.d0
               swj0=0.d0
               swjy=0.d0
               DO jw3=1,dlw3
	          j3=jw3-clw3+i3
	          if(j3.lt.1.or.j3.gt.n3) CYCLE
		  jwind3=(jw3-1)*dlw1*dlw2
	          jind3=(j3-1)*n1*n2
                  z3=(clw3-jw3)*wght(2)
                  z3=z3*z3
                  if(n2.gt.1) ih2=dsqrt(hakt2-z3)/wght(1)
                  DO jw2=clw2-ih2,clw2+ih2
	             j2=jw2-clw2+i2
	             if(j2.lt.1.or.j2.gt.n2) CYCLE
		     jwind2=jwind3+(jw2-1)*dlw1
	             jind2=(j2-1)*n1+jind3
                     z2=(clw2-jw2)*wght(1)
                     z2=z3+z2*z2
                     ih1=dsqrt(hakt2-z2)
                     DO jw1=clw1-ih1,clw1+ih1
C  first stochastic term
	                j1=jw1-clw1+i1
	                if(j1.lt.1.or.j1.gt.n1) CYCLE
                        jind=j1+jind2
                        z1=(clw1-jw1)
                        z1=z2+z1*z1
                        wj=lwght(jw1+jwind2)
                        swj0=swj0+wj
                        IF (aws) THEN
                           sij=bii*dmax1(kldist(model,thetai,
     1                             theta(jind),bii0)-sdiff,0.d0)
                           IF (sij.gt.1.d0) CYCLE
			      wj=wj*(1.d0-sij)
C   if sij <= spmin  this just keeps the location penalty
C    spmin = 0 corresponds to old choice of K_s 
C   new kernel is flat in [0,spmin] and then decays exponentially
                        END IF
                        heff=dmax1(heff,z1)
                        swj=swj+wj
                        swj2=swj2+wj*wj
                        swjy=swjy+wj*y(jind)
                     END DO
                  END DO
               END DO
               if(heff.lt.hakt2eff) fix(iind)=.TRUE.
               ai(iind)=swjy
               bi(iind)=swj
               bi2(iind)=swj2
               bi0(iind)=swj0
               call rchkusr()
            END DO
         END DO
      END DO
      RETURN
      END
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C   Perform one iteration in local constant three-variate aws (gridded)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      subroutine caws3(y,fix,n1,n2,hakt,lambda,theta,bi,bi2,bi0,ai,
     1                model,kern,spmin,lwght,swght)
C   
C   y        observed values of regression function
C   n1,n2,n3    design dimensions
C   hakt     actual bandwidth
C   lambda   lambda or lambda*sigma2 for Gaussian models
C   theta    estimates from last step   (input)
C   bi       \sum  Wi   (output)
C   ai       \sum  Wi Y     (output)
C   model    specifies the probablilistic model for the KL-Distance
C   kern     specifies the location kernel
C   wght     scaling factor for second and third dimension (larger values shrink)
C   
      implicit logical (a-z)
      external kldist,lkern
      real*8 kldist,lkern
      integer n1,n2,n3,model,kern
      logical aws,fix(1)
      real*8 y(1),theta(1),bi(1),bi0(1),ai(1),lambda,
     1       bi2(1),hakt,lwght(1),spmin,spf,swght(1)
      integer ih1,ih2,i1,i2,j1,j2,jw1,jw2,jwind2,
     1    iind,jind,jind2,clw,dlw,jwind1,
     2    clw1m1
      real*8 thetai,bii,sij,swj,swj2,swj0,swjy,z1,z2,z3,wj,hakt2,bii0,
     1       heff,hakt2eff
      hakt2=hakt*hakt
      spf=1.d0/(1.d0-spmin)
      ih1=hakt
      aws=lambda.lt.1d40
C
C   first calculate location weights
C
      ih2=hakt
      hakt2eff=ih2*ih2/1.26
      if(n2.eq.1) hakt2eff=ih2*ih2/1.563
      clw=ih2+1
      dlw=ih2+clw
      z2=0.d0
      DO j2=clw-ih2,clw+ih2
         if(n2.gt.1) THEN
            z2=(clw-j2)
            z2=z2*z2
            ih1=dsqrt(hakt2-z2)
            jind2=(j2-1)*dlw
	 ELSE
	    jind2=0
	 END IF
         DO j1=clw-ih1,clw+ih1
C  first stochastic term
            jind=j1+jind2
            z1=clw-j1
            lwght(jind)=lkern(kern,(z1*z1+z2)/hakt2)
         END DO
      END DO
      call rchkusr()
      DO i2=1,n2
         DO i1=1,n1
	    iind=i1+(i2-1)*n1
            IF (fix(iind)) CYCLE
            heff=0.d0
C    nothing to do, final estimate is already fixed by control 
            thetai=theta(iind)
            bii=bi(iind)/lambda
C   scaling of sij outside the loop
            bii0=bi0(iind)
            swj=0.d0
	    swj2=0.d0
            swj0=0.d0
            swjy=0.d0
            DO jw2=clw-ih2,clw+ih2
	       j2=jw2-clw+i2
	       jwind2=(jw2-1)*dlw
	       if(j2.lt.1.or.j2.gt.n2) THEN
                  DO jw1=1,dlw
                     swght(jw1+jwind2)=0.d0
                  END DO
                     CYCLE
               END IF
	       jind2=(j2-1)*n1
               z2=(clw-jw2)
               z2=z2*z2
               ih1=dsqrt(hakt2-z2)
               DO jw1=clw-ih1,clw+ih1
C  first stochastic term
	          j1=jw1-clw+i1
	          if(j1.lt.1.or.j1.gt.n1) CYCLE
                  jind=j1+jind2
                  z1=(clw-jw1)
                  z1=z2+z1*z1
                  jwind1=jw1+jwind2
                  IF (aws) THEN
                     sij=bii*kldist(model,thetai,theta(jind),bii0)
                     IF (sij.gt.1.d0) THEN
                        swght(jwind1)=0.d0
                     ELSE
			swght(jwind1)=lwght(jwind1)*(1.d0-sij)
                     END IF
C   if sij <= spmin  this just keeps the location penalty
C    spmin = 0 corresponds to old choice of K_s 
C   new kernel is flat in [0,spmin] and then decays exponentially
                  ELSE
                     swght(jwind1)=lwght(jwind1)
                  END IF
               END DO
            END DO
            if(dlw.gt.1) call chkwght2(swght,dlw,clw)
            DO jw2=clw-ih2,clw+ih2
	       j2=jw2-clw+i2
	       if(j2.lt.1.or.j2.gt.n2) CYCLE
	       jwind2=(jw2-1)*dlw
	       jind2=(j2-1)*n1
               z2=(clw-jw2)
               z2=z2*z2
               ih1=dsqrt(hakt2-z2)
               DO jw1=clw-ih1,clw+ih1
C  first stochastic term
	          j1=jw1-clw+i1
	          if(j1.lt.1.or.j1.gt.n1) CYCLE
                  jind=j1+jind2
                  z1=(clw-jw1)
                  z1=z2+z1*z1
                  wj=swght(jw1+jwind2)
                  IF(wj.le.0.d0) CYCLE
                  heff=dmax1(heff,z1)
                  swj0=swj0+wj
                  swj=swj+wj
                  swj2=swj2+wj*wj
                  swjy=swjy+wj*y(jind)
               END DO
            END DO
C            call dblepr("heff",4,heff,1)
C            call dblepr("hakt2eff",8,hakt2eff,1)
C            call dblepr("swght",5,swght,dlw*dlw)
            if(heff.lt.hakt2eff) fix(iind)=.TRUE.
            ai(iind)=swjy
            bi(iind)=swj
            bi2(iind)=swj2
            bi0(iind)=swj0
            call rchkusr()
         END DO
      END DO
      RETURN
      END
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C   Perform one iteration in local constant three-variate aws (gridded)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      subroutine chaws(y,fix,si2,n1,n2,n3,hakt,lambda,theta,bi,bi2,
     1           bi0,vred,ai,model,kern,spmin,lwght,wght)
C   
C   y        observed values of regression function
C   n1,n2,n3    design dimensions
C   hakt     actual bandwidth
C   lambda   lambda or lambda*sigma2 for Gaussian models
C   theta    estimates from last step   (input)
C   bi       \sum  Wi   (output)
C   ai       \sum  Wi Y     (output)
C   model    specifies the probablilistic model for the KL-Distance
C   kern     specifies the location kernel
C   wght     scaling factor for second and third dimension (larger values shrink)
C   
      implicit logical (a-z)
      external kldist,lkern
      real*8 kldist,lkern
      integer n1,n2,n3,model,kern
      logical aws,fix(1)
      real*8 y(1),theta(1),bi(1),bi0(1),ai(1),lambda,wght(2),
     1       bi2(1),hakt,lwght(1),si2(1),vred(1),spmin
      integer ih1,ih2,ih3,i1,i2,i3,j1,j2,j3,jw1,jw2,jw3,jwind3,jwind2,
     1        iind,jind,jind3,jind2,clw1,clw2,clw3,dlw1,dlw2,dlw3
      real*8 thetai,bii,sij,swj,swj2,swj0,swjy,z1,z2,z3,wj,hakt2,bii0,
     1        sv1,sv2,spf
      hakt2=hakt*hakt
      spf=1.d0/(1.d0-spmin)
      ih1=hakt
      aws=lambda.lt.1d40
C
C   first calculate location weights
C
      ih3=hakt/wght(2)
      ih2=hakt/wght(1)
      ih1=hakt
      if(n3.eq.1) ih3=0
      if(n2.eq.1) ih2=0
      clw1=ih1+1
      clw2=ih2+1
      clw3=ih3+1
      dlw1=ih1+clw1
      dlw2=ih2+clw2
      dlw3=ih3+clw3
      z2=0.d0
      z3=0.d0
      DO j3=1,dlw3
         if(n3.gt.1) THEN
            z3=(clw3-j3)*wght(2)
            z3=z3*z3
            ih2=dsqrt(hakt2-z3)/wght(1)
            jind3=(j3-1)*dlw1*dlw2
	 ELSE
	    jind3=0
	 END IF
         DO j2=clw2-ih2,clw2+ih2
            if(n2.gt.1) THEN
               z2=(clw2-j2)*wght(1)
               z2=z3+z2*z2
               ih1=dsqrt(hakt2-z2)
               jind2=jind3+(j2-1)*dlw1
	    ELSE
	       jind2=0
	    END IF
            DO j1=clw1-ih1,clw1+ih1
C  first stochastic term
               jind=j1+jind2
               z1=clw1-j1
               lwght(jind)=lkern(kern,(z1*z1+z2)/hakt2)
            END DO
         END DO
      END DO
      call rchkusr()
      DO i3=1,n3
         DO i2=1,n2
             DO i1=1,n1
	       iind=i1+(i2-1)*n1+(i3-1)*n1*n2
               IF (fix(iind)) CYCLE
C    nothing to do, final estimate is already fixed by control 
               thetai=theta(iind)
               bii=bi(iind)/lambda
C   scaling of sij outside the loop
               bii0=bi0(iind)
	       ih3=hakt/wght(2)
               swj=0.d0
	       swj2=0.d0
               swj0=0.d0
               swjy=0.d0
	       sv1=0.d0
	       sv2=0.d0
               DO jw3=1,dlw3
	          j3=jw3-clw3+i3
	          if(j3.lt.1.or.j3.gt.n3) CYCLE
	          jind3=(j3-1)*n1*n2
                  z3=(clw3-jw3)*wght(2)
                  z3=z3*z3
                  if(n2.gt.1) ih2=dsqrt(hakt2-z3)/wght(1)
		  jwind3=(jw3-1)*dlw1*dlw2
                  DO jw2=clw2-ih2,clw2+ih2
	             j2=jw2-clw2+i2
	             if(j2.lt.1.or.j2.gt.n2) CYCLE
	             jind2=(j2-1)*n1+jind3
                     z2=(clw2-jw2)*wght(1)
                     z2=z3+z2*z2
                     ih1=dsqrt(hakt2-z2)
		     jwind2=jwind3+(jw2-1)*dlw1
                     DO jw1=clw1-ih1,clw1+ih1
C  first stochastic term
	                j1=jw1-clw1+i1
	                if(j1.lt.1.or.j1.gt.n1) CYCLE
                        jind=j1+jind2
                        wj=lwght(jw1+jwind2)
                        swj0=swj0+wj*si2(jind)
                        IF (aws) THEN
                  sij=bii*kldist(model,thetai,theta(jind),bii0)
                           IF (sij.gt.1.d0) CYCLE
			   wj=wj*(1.d0-sij)
                        END IF
			sv1=sv1+wj
			sv2=sv2+wj*wj
                        swj=swj+wj*si2(jind)
                        swj2=swj2+wj*wj*si2(jind)
                        swjy=swjy+wj*si2(jind)*y(jind)
                     END DO
                  END DO
               END DO
               ai(iind)=swjy
               bi(iind)=swj
               bi2(iind)=swj2
               bi0(iind)=swj0
	       vred(iind)=sv2/sv1/sv1
               call rchkusr()
            END DO
         END DO
      END DO
      RETURN
      END
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C   Perform one iteration in local constant three-variate aws (gridded)
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      subroutine cgaws(y,fix,si2,n1,n2,n3,hakt,lambda,theta,bi,bi2,
     1        bi0,gi,vred,ai,model,kern,spmin,lwght,wght)
C   
C   y        observed values of regression function
C   n1,n2,n3    design dimensions
C   hakt     actual bandwidth
C   lambda   lambda or lambda*sigma2 for Gaussian models
C   theta    estimates from last step   (input)
C   bi       \sum  Wi   (output)
C   ai       \sum  Wi Y     (output)
C   model    specifies the probablilistic model for the KL-Distance
C   kern     specifies the location kernel
C   wght     scaling factor for second and third dimension (larger values shrink)
C   
      implicit logical (a-z)
      external kldist,lkern
      real*8 kldist,lkern
      integer n1,n2,n3,model,kern
      logical aws,fix(1)
      real*8 y(1),theta(1),bi(1),bi0(1),ai(1),lambda,wght(2),
     1       bi2(1),hakt,lwght(1),si2(1),vred(1),spmin,gi(1)
      integer ih1,ih2,ih3,i1,i2,i3,j1,j2,j3,jw1,jw2,jw3,jwind3,jwind2,
     1        iind,jind,jind3,jind2,clw1,clw2,clw3,dlw1,dlw2,dlw3
      real*8 thetai,bii,sij,swj,swj2,swj0,swjy,z1,z2,z3,wj,hakt2,bii0,
     1        sv1,sv2,spf,z
      hakt2=hakt*hakt
      spf=1.d0/(1.d0-spmin)
      ih1=hakt
      aws=lambda.lt.1d40
C
C   first calculate location weights
C
      ih3=hakt/wght(2)
      ih2=hakt/wght(1)
      ih1=hakt
      if(n3.eq.1) ih3=0
      if(n2.eq.1) ih2=0
      clw1=ih1+1
      clw2=ih2+1
      clw3=ih3+1
      dlw1=ih1+clw1
      dlw2=ih2+clw2
      dlw3=ih3+clw3
      z2=0.d0
      z3=0.d0
      DO j3=1,dlw3
         if(n3.gt.1) THEN
            z3=(clw3-j3)*wght(2)
            z3=z3*z3
            ih2=dsqrt(hakt2-z3)/wght(1)
            jind3=(j3-1)*dlw1*dlw2
	 ELSE
	    jind3=0
	 END IF
         DO j2=clw2-ih2,clw2+ih2
            if(n2.gt.1) THEN
               z2=(clw2-j2)*wght(1)
               z2=z3+z2*z2
               ih1=dsqrt(hakt2-z2)
               jind2=jind3+(j2-1)*dlw1
	    ELSE
	       jind2=0
	    END IF
            DO j1=clw1-ih1,clw1+ih1
C  first stochastic term
               jind=j1+jind2
               z1=clw1-j1
               lwght(jind)=lkern(kern,(z1*z1+z2)/hakt2)
            END DO
         END DO
      END DO
      call rchkusr()
      DO i3=1,n3
         DO i2=1,n2
             DO i1=1,n1
	       iind=i1+(i2-1)*n1+(i3-1)*n1*n2
               IF (fix(iind)) CYCLE
C    nothing to do, final estimate is already fixed by control 
               thetai=theta(iind)
               bii=bi(iind)/lambda
C   scaling of sij outside the loop
               bii0=bi0(iind)
	       ih3=hakt/wght(2)
               swj=0.d0
	       swj2=0.d0
               swj0=0.d0
               swjy=0.d0
	       sv1=0.d0
	       sv2=0.d0
               DO jw3=1,dlw3
	          j3=jw3-clw3+i3
	          if(j3.lt.1.or.j3.gt.n3) CYCLE
	          jind3=(j3-1)*n1*n2
                  z3=(clw3-jw3)*wght(2)
                  z3=z3*z3
                  if(n2.gt.1) ih2=dsqrt(hakt2-z3)/wght(1)
		  jwind3=(jw3-1)*dlw1*dlw2
                  DO jw2=clw2-ih2,clw2+ih2
	             j2=jw2-clw2+i2
	             if(j2.lt.1.or.j2.gt.n2) CYCLE
	             jind2=(j2-1)*n1+jind3
                     z2=(clw2-jw2)*wght(1)
                     z2=z3+z2*z2
                     ih1=dsqrt(hakt2-z2)
		     jwind2=jwind3+(jw2-1)*dlw1
                     DO jw1=clw1-ih1,clw1+ih1
C  first stochastic term
	                j1=jw1-clw1+i1
	                if(j1.lt.1.or.j1.gt.n1) CYCLE
                        jind=j1+jind2
                        wj=lwght(jw1+jwind2)
                        swj0=swj0+wj*si2(jind)
                        IF (aws) THEN
C
C                  sij=bii*kldist(model,thetai,theta(jind),bii0)
C
C      gaussian case only
C
                           z=(thetai-theta(jind))
                           sij=bii*z*z
                           IF (sij.gt.1.d0) CYCLE
			   wj=wj*(1.d0-sij)
                        END IF
			sv1=sv1+wj
			sv2=sv2+wj*wj
                        swj=swj+wj*si2(jind)
                        swj2=swj2+wj*wj*si2(jind)
                        swjy=swjy+wj*si2(jind)*y(jind)
                     END DO
                  END DO
               END DO
               ai(iind)=swjy
               bi(iind)=swj
               bi2(iind)=swj2
               bi0(iind)=swj0
	       gi(iind)=sv1
	       vred(iind)=sv2/sv1/sv1
               call rchkusr()
            END DO
         END DO
      END DO
      RETURN
      END
c
c     invers computes the inverse of a certain
c     double precision symmetric positive definite matrix (see below)
c     
c     this code is based on choleski decomposition and
c     integrates code from linpack (dpofa.f and dpodi.f, version of 08/14/78 .
c     cleve moler, university of new mexico, argonne national lab.)
c     and BLAS
C
c     on entry
c
c        a       double precision(n, n)
c
c        n       integer
c                the order of the matrix  a .
c
c
c     on return
c
c        a       invers produces the upper half of inverse(a) .
c
c     subroutines and functions
c
c     fortran dsqrt
c
      subroutine invers(a, n, info)
      integer n,info
      double precision a(n,n)
c
c     internal variables
c
      double precision ddot,t
      double precision s
      integer j,jm1,k,l,i,kp1,im1
c     begin block with ...exits to 940 if singular (info.ne.0)
c
c
      DO j = 1, n
         info = j
         s = 0.0d0
         jm1 = j - 1
         IF (jm1 .ge. 1) THEN
            DO k = 1, jm1
               ddot=0.0d0
               DO l=1,k-1
                  ddot=ddot+a(l,k)*a(l,j)
               END DO           
               t = a(k,j) - ddot
               t = t/a(k,k)
               a(k,j) = t
               s = s + t*t
            END DO
	 END IF
         s = a(j,j) - s
c     .....exit
         IF (s .le. 1.d-100) RETURN
         a(j,j) = dsqrt(s)
      END DO
      info = 0
c
c     now we have the choeski decomposition in a     
c
c     next code from dpodi to compute inverse
c
      DO k = 1, n
         a(k,k) = 1.0d0/a(k,k)
         t = -a(k,k)
         DO l=1,k-1
            a(l,k)=t*a(l,k)
         END DO          
         kp1 = k + 1
         IF (n .ge. kp1) THEN
            DO j = kp1, n
               t = a(k,j)
               a(k,j) = 0.0d0
               DO l=1,k
                  a(l,j)=a(l,j)+t*a(l,k)
               END DO       
            END DO
         END IF
      END DO
c
c        form  inverse(r) * trans(inverse(r))
c
      DO j = 1, n
         jm1 = j - 1
         IF (jm1 .ge. 1) THEN
            DO k = 1, jm1
               t = a(k,j)
               DO l=1,k
                  a(l,k)=a(l,k)+t*a(l,j)
               END DO       
            END DO
	 END IF
         t = a(j,j)
         DO l=1,j
            a(l,j)=t*a(l,j)
         END DO          
      END DO
c
c     now fill lower triangle       
c  
      DO i=1,n
         im1 = i-1
         DO j=1,im1
            a(i,j) = a(j,i)
         END DO
      END DO
      RETURN
      END

      subroutine chkwght2(sw,dlw,clw)
      integer dlw
      real*8 sw(dlw,dlw),w
      integer clw,i1,i2,j1,j2,k
      i1=clw
      i2=clw
      DO k=1,clw-1
         j1=i1+k
         DO j2=i2-k+1,i2+k-1
            IF(dmax1(sw(j1-1,j2),sw(j1-1,j2-1),sw(j1-1,j2+1)).le.0.d0)
     1         sw(j1,j2)=0.d0
         END DO
         j1=i1-k
         DO j2=i2-k+1,i2+k-1
            IF(dmax1(sw(j1+1,j2),sw(j1+1,j2-1),sw(j1+1,j2+1)).le.0.d0)
     1         sw(j1,j2)=0.d0
         END DO
         j2=i2+k
         DO j2=i2-k+1,i2+k-1
            IF(dmax1(sw(j1,j2-1),sw(j1-1,j2-1),sw(j1+1,j2-1)).le.0.d0)
     1         sw(j1,j2)=0.d0
         END DO
         j2=i2-k
         DO j2=i2-k+1,i2+k-1
            IF(dmax1(sw(j1,j2-1),sw(j1-1,j2-1),sw(j1+1,j2-1)).le.0.d0)
     1         sw(j1,j2)=0.d0
         END DO
         IF(dmax1(sw(i1+k-1,i2+k),sw(i1+k,i2+k-1)).le.0.d0) 
     1                      sw(i1+k,i2+k)=0.d0 
         IF(dmax1(sw(i1-k+1,i2+k),sw(i1-k,i2+k-1)).le.0.d0) 
     1                      sw(i1-k,i2+k)=0.d0 
         IF(dmax1(sw(i1+k-1,i2-k),sw(i1+k,i2-k+1)).le.0.d0) 
     1                      sw(i1+k,i2-k)=0.d0 
         IF(dmax1(sw(i1-k+1,i2-k),sw(i1-k,i2-k+1)).le.0.d0) 
     1                      sw(i1-k,i2-k)=0.d0 
      END DO
      RETURN
      END
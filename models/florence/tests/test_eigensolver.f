C     Known-answer regression test for F02AXF (LAPACK ZHEEV-backed
C     complex Hermitian eigensolver). Self-contained: no dependency on
C     the original NAG-derived implementation this replaced, since
C     that code no longer exists in this bundle - see NOTICE for the
C     one-time head-to-head verification against it that was done
C     before this replacement was committed.
      PROGRAM TESTEIGENSOLVER
      IMPLICIT NONE
      INTEGER N, MBRANC
      PARAMETER (MBRANC=3)
      DOUBLE PRECISION AR(MBRANC,MBRANC), AI(MBRANC,MBRANC)
      DOUBLE PRECISION WR(MBRANC), VR(MBRANC,MBRANC), VI(MBRANC,MBRANC)
      DOUBLE PRECISION WK1(MBRANC), WK2(MBRANC), WK3(MBRANC)
      INTEGER IFAIL
      DOUBLE PRECISION TOL
      PARAMETER (TOL=1.0D-12)
      LOGICAL OK
      OK = .TRUE.

C     Case 1: diagonal matrix, trivially known eigenvalues 2,3,5.
      N = 3
      AR(1,1)=2.0D0
      AR(1,2)=0.0D0
      AR(1,3)=0.0D0
      AR(2,1)=0.0D0
      AR(2,2)=3.0D0
      AR(2,3)=0.0D0
      AR(3,1)=0.0D0
      AR(3,2)=0.0D0
      AR(3,3)=5.0D0
      AI(1,1)=0.0D0
      AI(1,2)=0.0D0
      AI(1,3)=0.0D0
      AI(2,1)=0.0D0
      AI(2,2)=0.0D0
      AI(2,3)=0.0D0
      AI(3,1)=0.0D0
      AI(3,2)=0.0D0
      AI(3,3)=0.0D0
      IFAIL = 0
      CALL F02AXF(AR,MBRANC,AI,MBRANC,N,WR,VR,MBRANC,VI,MBRANC,
     $            WK1,WK2,WK3,IFAIL)
      IF (IFAIL.NE.0) THEN
         PRINT *, 'CASE 1: unexpected IFAIL=', IFAIL
         OK = .FALSE.
      END IF
      IF (ABS(WR(1)-2.0D0).GT.TOL .OR. ABS(WR(2)-3.0D0).GT.TOL .OR.
     $    ABS(WR(3)-5.0D0).GT.TOL) THEN
         PRINT *, 'CASE 1 FAIL: eigenvalues', WR(1), WR(2), WR(3)
         OK = .FALSE.
      ELSE
         PRINT *, 'CASE 1 PASS'
      END IF

C     Case 2: [[0,1-i],[1+i,0]], known eigenvalues +-sqrt(2), and
C     known (up to the routine's own phase normalization) eigenvectors
C     - see the commit that added this test for the by-hand derivation.
      N = 2
      AR(1,1)=0.0D0
      AI(1,1)=0.0D0
      AR(2,1)=1.0D0
      AI(2,1)=1.0D0
      AR(2,2)=0.0D0
      AI(2,2)=0.0D0
      IFAIL = 0
      CALL F02AXF(AR,MBRANC,AI,MBRANC,N,WR,VR,MBRANC,VI,MBRANC,
     $            WK1,WK2,WK3,IFAIL)
      IF (IFAIL.NE.0) THEN
         PRINT *, 'CASE 2: unexpected IFAIL=', IFAIL
         OK = .FALSE.
      END IF
      IF (ABS(WR(1)-(-SQRT(2.0D0))).GT.TOL .OR.
     $    ABS(WR(2)-SQRT(2.0D0)).GT.TOL) THEN
         PRINT *, 'CASE 2 FAIL: eigenvalues', WR(1), WR(2)
         OK = .FALSE.
      ELSE IF (ABS(VR(1,2)-0.70710678118654752D0).GT.TOL .OR.
     $         ABS(VR(2,2)-0.5D0).GT.TOL .OR.
     $         ABS(VI(2,2)-0.5D0).GT.TOL) THEN
         PRINT *, 'CASE 2 FAIL: eigenvector 2', VR(1,2), VR(2,2),
     $            VI(2,2)
         OK = .FALSE.
      ELSE
         PRINT *, 'CASE 2 PASS'
      END IF

      IF (OK) THEN
         PRINT *, 'PASS: F02AXF eigensolver known-answer tests'
      ELSE
         PRINT *, 'FAIL: F02AXF eigensolver known-answer tests'
         STOP 1
      END IF
      END

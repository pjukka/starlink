      SUBROUTINE PDA_CHLDCD(NR,N,A,DIAGMX,TOL,ADDMAX)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C PURPOSE
C -------
C FIND THE PERTURBED L(L-TRANSPOSE) [WRITTEN LL+] DECOMPOSITION
C OF A+D, WHERE D IS A NON-NEGATIVE DIAGONAL MATRIX ADDED TO A IF
C NECESSARY TO ALLOW THE CHOLESKY DECOMPOSITION TO CONTINUE.
C
C PARAMETERS
C ----------
C NR           --> ROW DIMENSION OF MATRIX
C N            --> DIMENSION OF PROBLEM
C A(N,N)      <--> ON ENTRY: MATRIX FOR WHICH TO FIND PERTURBED
C                       CHOLESKY DECOMPOSITION
C                  ON EXIT:  CONTAINS L OF LL+ DECOMPOSITION
C                  IN LOWER TRIANGULAR PART AND DIAGONAL OF "A"
C DIAGMX       --> MAXIMUM DIAGONAL ELEMENT OF "A"
C TOL          --> TOLERANCE
C ADDMAX      <--  MAXIMUM AMOUNT IMPLICITLY ADDED TO DIAGONAL OF "A"
C                  IN FORMING THE CHOLESKY DECOMPOSITION OF A+D
C INTERNAL VARIABLES
C ------------------
C AMINL    SMALLEST ELEMENT ALLOWED ON DIAGONAL OF L
C AMNLSQ   =AMINL**2
C OFFMAX   MAXIMUM OFF-DIAGONAL ELEMENT IN COLUMN OF A
C
C
C DESCRIPTION
C -----------
C THE NORMAL CHOLESKY DECOMPOSITION IS PERFORMED.  HOWEVER, IF AT ANY
C POINT THE ALGORITHM WOULD ATTEMPT TO SET L(I,I)=SQRT(TEMP)
C WITH TEMP < TOL*DIAGMX, THEN L(I,I) IS SET TO SQRT(TOL*DIAGMX)
C INSTEAD.  THIS IS EQUIVALENT TO ADDING TOL*DIAGMX-TEMP TO A(I,I)
C
C
      DIMENSION A(NR,1)
C
      ADDMAX=0.D0
      AMINL=SQRT(DIAGMX*TOL)
      AMNLSQ=AMINL*AMINL
C
C FORM COLUMN J OF L
C
      DO 100 J=1,N
C FIND DIAGONAL ELEMENTS OF L
        SUM=0.D0
        IF(J.EQ.1) GO TO 20
        JM1=J-1
        DO 10 K=1,JM1
          SUM=SUM + A(J,K)*A(J,K)
   10   CONTINUE
   20   TEMP=A(J,J)-SUM
        IF(TEMP.LT.AMNLSQ) GO TO 30
C       IF(TEMP.GE.AMINL**2)
C       THEN
          A(J,J)=SQRT(TEMP)
          GO TO 40
C       ELSE
C
C FIND MAXIMUM OFF-DIAGONAL ELEMENT IN COLUMN
   30     OFFMAX=0.D0
          IF(J.EQ.N) GO TO 37
          JP1=J+1
          DO 35 I=JP1,N
            IF(ABS(A(I,J)).GT.OFFMAX) OFFMAX=ABS(A(I,J))
   35     CONTINUE
   37     IF(OFFMAX.LE.AMNLSQ) OFFMAX=AMNLSQ
C
C ADD TO DIAGONAL ELEMENT  TO ALLOW CHOLESKY DECOMPOSITION TO CONTINUE
          A(J,J)=SQRT(OFFMAX)
          ADDMAX=MAX(ADDMAX,OFFMAX-TEMP)
C       ENDIF
C
C FIND I,J ELEMENT OF LOWER TRIANGULAR MATRIX
   40   IF(J.EQ.N) GO TO 100
        JP1=J+1
        DO 70 I=JP1,N
          SUM=0.0D0
          IF(J.EQ.1) GO TO 60
          JM1=J-1
          DO 50 K=1,JM1
            SUM=SUM+A(I,K)*A(J,K)
   50     CONTINUE
   60     A(I,J)=(A(I,J)-SUM)/A(J,J)
   70   CONTINUE
  100 CONTINUE
      RETURN
      END

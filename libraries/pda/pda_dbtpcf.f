

      SUBROUTINE PDA_DBTPCF(X,N,FCN,LDF,NF,T,K,BCOEF,WORK,IFLAG)

C***BEGIN PROLOGUE  DBTPCF
C***REFER TO  DB2INK,DB3INK
C***ROUTINES CALLED  DBINTK,DBNSLV
C***END PROLOGUE  DBTPCF
C
C  -----------------------------------------------------------------
C  DBTPCF COMPUTES B-SPLINE INTERPOLATION COEFFICIENTS FOR NF SETS
C  OF DATA STORED IN THE COLUMNS OF THE ARRAY FCN. THE B-SPLINE
C  COEFFICIENTS ARE STORED IN THE ROWS OF BCOEF HOWEVER.
C  EACH INTERPOLATION IS BASED ON THE N ABCISSA STORED IN THE
C  ARRAY X, AND THE N+K KNOTS STORED IN THE ARRAY T. THE ORDER
C  OF EACH INTERPOLATION IS K. THE WORK ARRAY MUST BE OF LENGTH
C  AT LEAST 2*K*(N+1).
C  DOUBLE PRECISION VERSION OF BTPCF.
C  -----------------------------------------------------------------
C
C  ------------
C  DECLARATIONS
C  ------------
C
C  PARAMETERS
C
      INTEGER
     *        N, LDF, K,NF
      INTEGER IFLAG
      DOUBLE PRECISION
     *     X(N), FCN(LDF,NF), T(1), BCOEF(NF,N), WORK(1)
C
C  LOCAL VARIABLES
C
      INTEGER
     *        I, J, K1, K2, IQ, IW
C
C  ---------------------------------------------
C  CHECK FOR NULL INPUT AND PARTITION WORK ARRAY
C  ---------------------------------------------
C
C***FIRST EXECUTABLE STATEMENT
      IF (NF .LE. 0)  GO TO 500
      K1 = K - 1
      K2 = K1 + K
      IQ = 1 + N
      IW = IQ + K2*N+1
C
C  -----------------------------
C  COMPUTE B-SPLINE COEFFICIENTS
C  -----------------------------
C
C
C   FIRST DATA SET
C
      CALL PDA_DBINTK(X,FCN,T,N,K,WORK,WORK(IQ),WORK(IW),IFLAG)
      DO 20 I=1,N
         BCOEF(1,I) = WORK(I)
   20 CONTINUE
C
C  ALL REMAINING DATA SETS BY BACK-SUBSTITUTION
C
      IF (NF .EQ. 1)  GO TO 500
      DO 100 J=2,NF
         DO 50 I=1,N
            WORK(I) = FCN(I,J)
   50    CONTINUE
         CALL PDA_DBNSLV(WORK(IQ),K2,N,K1,K1,WORK)
         DO 60 I=1,N
            BCOEF(J,I) = WORK(I)
   60    CONTINUE
  100 CONTINUE
C
C  ----
C  EXIT
C  ----
C
  500 CONTINUE
      RETURN

      END

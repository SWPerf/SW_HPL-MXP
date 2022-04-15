#set -x
export SWCH_CG_PER_PROCESS=6

code_prefix=hpl-ai
code_suffix=ed56e59

code_name=$code_prefix.$code_suffix

if [ $# -lt 3 ]
then
	echo "Usage: sh run.sh queuename P Q"
	exit
fi

queuename=$1

P=$2
Q=$3

SPACE_IN_USE=80.0	# memory used in HPL-AI test. GB

date_pro=`date +%y%m%d%H%M%S`

./tools/matrix_size_shape $P $Q 1024 $SPACE_IN_USE 0.5 > /tmp/.hpl-ai.conf.$date_pro

P=`awk '{print $1}' /tmp/.hpl-ai.conf.$date_pro`
Q=`awk '{print $2}' /tmp/.hpl-ai.conf.$date_pro`
N=`awk '{print $3}' /tmp/.hpl-ai.conf.$date_pro`
firstpart=`awk '{print $4}' /tmp/.hpl-ai.conf.$date_pro`

cpu_num=$(($P*$Q))


if [ ! -e result ]
then
	mkdir result
fi

HPL_info="HPLinpack benchmark input file \n
Innovative Computing Laboratory, University of Tennessee \n
HPL.out      \toutput file name (if any) \n
6            \tdevice out (6=stdout,7=stderr,file) \n
1	         \t# of problems sizes (N) \n
$N		     \tNs  \n
1            \t# of NBs \n
1024         \tNBs \n
0            \tPMAP process mapping (0=Row-,1=Column-major) \n
1            \t# of process grids (P x Q) \n
$P           \tPs  \n
$Q           \tQs  \n
16.0         \tthreshold \n
1		     \t# of panel fact \n
1            \tPFACTs (0=left, 1=Crout, 2=Right) \n
1            \t# of recursive stopping criterium \n
4            \tNBMINs (>= 1) \n
1            \t# of panels in recursion \n
2            \tNDIVs \n
1			 \t# of recursive panel fact. \n
1			 \tRFACTs (0=left, 1=Crout, 2=Right) \n
1		     \t# of broadcast \n
0			 \tBCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM,6=1r2r,7=2r2r,8=2t2r,9=t2r,10=hybrid) \n
1            \t# of lookahead depth \n
1            \tDEPTHs (>=0) \n
1			 \tSWAP (0=bin-exch,1=long,2=mix) \n
512          \tswapping threshold \n
1            \tL1 in (0=transposed,1=no-transposed) form \n
1            \tU  in (0=transposed,1=no-transposed) form \n
1			 \tEquilibration (0=no,1=yes) \n
32           \tmemory alignment in double (> 0)"
echo -e $HPL_info > HPL.dat

bsub -I -o result/log."$P"x"$Q".$date_pro -pr -q $queuename -N $cpu_num -np 6 -cgsp 64 -share_size 64 -cross_size 93504 -priv_size 1 -ro_size 16 -cache_size 0 -swrun ./tools/swrun-84 -swrunarg "-o 6" ./$code_name -f $firstpart -c 0

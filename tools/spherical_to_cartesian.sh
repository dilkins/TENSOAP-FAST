#!/bin/bash

lval=${1}
if [ ${lval} == 1 ];then
	export fname1=${2}
	export degen=3
	export ncommittee=$(head -n 1 ${fname1} | awk '{print NF/ENVIRON["degen"]}')
	for i in $(seq 1 ${ncommittee});do
		export ii=${i}
		cat ${fname1} | awk 'BEGIN{dg=ENVIRON["degen"];ii=ENVIRON["ii"]}{i1=(ii-1)*dg + 1;i2=ii*dg;for (i=i1;i<=i2;i++){printf "%f ",$i};printf "\n"}' | awk '{printf "%f %f %f\n",$3,$1,$2}' > MODEL_${fname1}_${i}
	done
	oname=${3}
	paste MODEL_${fname1}_* > ${oname}
elif [ ${lval} == 2 ];then
	fname0=${2}
	fname2=${3}
	export degen0=1
	export degen2=5
	export ncommittee=$(head -n 1 ${fname0} | awk '{print NF/ENVIRON["degen0"]}')
	export ncommitte2=$(head -n 1 ${fname2} | awk '{print NF/ENVIRON["degen2"]}')
	if [ ${ncommittee} -ne ${ncommitte2} ];then
		echo "ERROR: different numbers of committees for two models"
		echo ${ncommittee} ${ncommitte2}
		exit
	fi
	for i in $(seq 1 ${ncommittee});do
		export ii=${i}
		cat ${fname0} | awk 'BEGIN{dg=ENVIRON["degen0"];ii=ENVIRON["ii"]}{i1=(ii-1)*dg + 1;i2=ii*dg;for (i=i1;i<=i2;i++){printf "%f ",$i};printf "\n"}' > MODEL_${fname0}_${i}
		cat ${fname2} | awk 'BEGIN{dg=ENVIRON["degen2"];ii=ENVIRON["ii"]}{i1=(ii-1)*dg + 1;i2=ii*dg;for (i=i1;i<=i2;i++){printf "%f ",$i};printf "\n"}' > MODEL_${fname2}_${i}
		paste MODEL_${fname0}_${i} MODEL_${fname2}_${i} | awk 'BEGIN{f1=(1./3.)**0.5;f2=(3./2.)**0.5}{a0=$1;a2m2=$2;a2m1=$3;a20=$4;a2p1=$5;a2p2=$6;axy=ayx=a2m2;ayz=azy=a2m1;axz=azx=a20;axx=f1*(-a0-a2p1 + f2*a2p2);ayy=f1*(-a0-a2p1 - f2*a2p2);azz=f1*(-a0 + 2*a2p1);printf "%f %f %f %f %f %f %f %f %f\n",axx,axy,axz,ayx,ayy,ayz,azx,azy,azz}'
	done
elif [ ${lval} == 0 ];then
	echo "No conversion needed"
	exit
else
	echo "This l value is not supported"
	exit
fi
#rm MODEL_*
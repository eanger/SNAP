#!/bin/bash

#haswell i7-4770k
l1size=32768
l2size=262144
#l3size=8388608
l3size=2097152

l1code=r5301d1
#l2code=r530324
l2code=r53e724
l3code=r534f2e
#memcode=r53012e
memcode=r50412e

executable=../src/snap-opt
export OMP_NUM_THREADS=4
export OMP_PLACES=cores

iters=10

get_probsize(){
    local res
    let "res=$1*$1"
    echo -n "$res"
}

files="byfl.out dinero.out perf.out"
for file in $files
do
    echo -e "problem size\tl1 accesses\tl2 accesses\tl3 accesses\t mem accesses" > $file
done

#for size in 4 6 8 10 12 14 16 17 18 19 20 25
#for size in `seq 10 10 100`
for size in `seq 4 8`
do
    #initialize invar file
    cp base.ini invar.ini
    echo -e "  ny=$size\n  nx=$size\n/" >> invar.ini

    # initialize output files
    probsize=$(get_probsize $size)
    for file in $files
    do
        echo -e -n "$probsize\t" >> $file
    done

    #get perf counter values
    l1val=0
    l2val=0
    l3val=0
    memval=0
    for count in `seq $iters`
    do
        perf stat -e $l1code,$l2code,$l3code,$memcode $executable-orig invar.ini outvar 2>&1 | tee perf.tmp
        let "l1val=$l1val+$(grep $l1code perf.tmp | awk '{print $1}' | tr -d ',')"
        let "l2val=$l2val+$(grep $l2code perf.tmp | awk '{print $1}' | tr -d ',')"
        let "l3val=$l3val+$(grep $l3code perf.tmp | awk '{print $1}' | tr -d ',')"
        let "memval=$memval+$(grep $memcode perf.tmp | awk '{print $1}' | tr -d ',')"
        rm perf.tmp
    done
    let "l1val=l1val/$iters"
    let "l2val=l2val/$iters"
    let "l3val=l3val/$iters"
    let "memval=memval/$iters"
    echo -e "$l1val\t$l2val\t$l3val\t$memval" >> perf.out

    #get byfl and dinero values
    $executable-byfl invar.ini outvar
    get-accesses.py cache.dump $l1size $l2size $l3size >> byfl.out
    sed '2q;d' dinero.dump >> dinero.out

    #save outputs for later reference
    mv cache.dump cache.dump.$size
    mv dinero.dump dinero.dump.$size
done

for src in benchmark_*${1}.S; do
  #echo $src
  BNAME=${src%%.S}
  echo $BNAME
  gcc $src ffi.c -g -o $BNAME
	objdump $BNAME -M intel -d > "${BNAME}_dump.txt"
	TIMEFORMAT=%R
  for i in `seq 10`
  do
    time ./$BNAME
  done
  #echo "returned $?"
done

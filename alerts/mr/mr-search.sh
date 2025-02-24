ual=~/ual

#NRT-SIN
rm nrt-sin-*1.txt
paste <(date | $ual/src/date-add.py 3) <(echo '12/31/15') <(echo 'NRT	SIN		R') > nrt-sin-search1.txt
$ual/src/ual.py -c ~/ual.config -a -o nrt-sin-results1.txt nrt-sin-search1.txt 

#HKG-SFO the next day
rm hkg-sfo-*.txt
paste <(cut -f1 -d' ' nrt-sin-results1.txt | $ual/src/date-add.py 1 | awk -v OFS='\t' '{print $1,$1}') <(
  awk -v OFS="\t" '{print $3,$5,$8,$8}' nrt-sin-results1.txt) | 
  sed -E 's/R[0-9]+//' | sed -E 's/R[0-9]+/R/' | sed 's/NRT/HKG/' | sed 's/SIN/SFO/' |
  grep -v 'found' > hkg-sfo-search.txt 
$ual/src/ual.py -c ~/ual.config -a -o hkg-sfo-results.txt hkg-sfo-search.txt  

#rerun NRT-SIN search from HKG-SFO results
rm nrt-sin-*2.txt
paste <(cut -f1 -d' ' hkg-sfo-results.txt | $ual/src/date-add.py -1 | awk -v OFS='\t' '{print $1,$1}') <(
  awk -v OFS="\t" '{print $3,$5,$8,$8}' hkg-sfo-results.txt) | 
  sed -E 's/R[0-9]+//' | sed -E 's/R[0-9]+/R/' | sed 's/HKG/NRT/' | sed 's/SFO/SIN/' |
  grep -v 'found' > nrt-sin-search2.txt 
$ual/src/ual.py -c ~/ual.config -a -o nrt-sin-results2.txt nrt-sin-search2.txt 

#SIN-HKG
rm sin-hkg-*.txt
paste <(cut -f1 -d' ' hkg-sfo-results.txt | $ual/src/date-add.py 0 | awk -v OFS='\t' '{print $1,$1}') <(
  awk -v OFS="\t" '{print $3,$5,$8,$8}' hkg-sfo-results.txt) | 
  sed -E 's/R[0-9]+//' | sed -E 's/R[0-9]+/R/' | sed 's/HKG/SIN/' | sed 's/SFO/HKG/' |
  grep -v 'found' > sin-hkg-search.txt 
$ual/src/ual.py -c ~/ual.config -a -o sin-hkg-results.txt sin-hkg-search.txt  

#SFO/LAX/DEN-NRT
rm sfo-nrt-*.txt
paste <(cut -f1 -d' ' hkg-sfo-results.txt | $ual/src/date-add.py -2 | awk -v OFS='\t' '{print $1,$1}')  <(
  awk -v OFS="\t" '{print $3,$5,$8,$8}' hkg-sfo-results.txt) |
  grep -v 'found' | sed -E 's/R[0-9]+//' | sed -E 's/R[0-9]+/R/' |
  while read a; do
    echo "$a" | sed 's/SFO/NRT/' | sed 's/HKG/SFO/'
    echo "$a" | sed 's/SFO/NRT/' | sed 's/HKG/LAX/'
    echo "$a" | sed 's/SFO/NRT/' | sed 's/HKG/DEN/'
  done >sfo-nrt-search.txt
$ual/src/ual.py -c ~/ual.config -a -o sfo-nrt-results.txt sfo-nrt-search.txt 

#combine them all and send an email
cat sfo-nrt-results.txt nrt-sin-results2.txt sin-hkg-results.txt hkg-sfo-results.txt | grep -v HND | 
  awk -v OFS="\t" '{print $1,$1,$3,$5,$8,$8}' | grep -v 'found' |
  sed -E 's/R[0-9]+//' | sed -E 's/R[0-9]+/R/' > mr-search.txt
$ual/src/ual.py -c ~/ual.config -a mr-search.txt -s 'Mileage run search results' 

****Issues****
Missing </P>
 ex: find in file: <P>/n<P>, 
 References/n<P>

Data with special character:
 ex: &, <https, <-https

Data inconsistency
 + Sometime: start_par=1 , start_par=0 
    ex: find: The cost of raw materials has risen significantly from the year 2003 to year 2009 and it has affected the electronics supply chain. We will look at two very important components in the manufacture of electronic components, gold and copper.

    <MISTAKE start_par="2" start_off="329" end_par="2" end_off="334">

 + Start_para != end_para
    ex: <MISTAKE start_par="2" start_off="1416" end_par="3" end_off="0">



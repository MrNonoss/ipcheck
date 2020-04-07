# ipcheck.sh
Mass IP checker, using iphunter.info, getipintel.net, and metrics.torproject.org<br>
<br>
The synthax is pretty simple: "ipcheck.sh $1 $2"<br>
Where $1 is your input file and $2 your destination file.<br>
<br>
This bash script let user choose between 3 differents checks results with an IP reliability score.<br>
You are offered the possibility to input a list of raw IPs, or a CSV were you will be able to choose the right column.<br>
<br>
For it to be functionnal, you will have to provide a valid mail contact that will be used as a token (for getipintel), and also an API key from iphunter.<br>
TIP: Changes are lines 23 and 24 of the script.<br>
<br>
Please note two things:<br>
-->The destination file will be overwritten if previously existant.<br>
--> If you input file contains several columns, every space " " in input file will be replaced by "\*".<br>
<br>
The deeper the search is, the longer it takes<br>
- The first check is fast -> Country, ISP and Reputation using iphunter (~0,3s/IP).<br>
- The second check is middle -> Same as before, plus getipintel (~1s/IP).<br>
- The third one is long -> Same as before, plus check within the TOR descriptors (~2s/IP).<br>
<br>
<img class="fit-picture"
     src="ipcheck.PNG"
     alt="view of the script"

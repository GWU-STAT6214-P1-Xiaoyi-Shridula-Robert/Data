options symbolgen;
/*
Story Name: Air Pollution Data 

Reference: Sokal, R.R. and Rohlf, F.J. (1981) Biometry, 2nd edition, 
	San Francisco: W.H. Freeman, 239. 
Also found in: Hand, D.J., et al. (1994) A Handbook of Small Data Sets, 
	London: Chapman & Hall, 20-21. 
	
Description: These data give air pollution and related values for 41 
	U.S. cities and were collected from U.S. government publications. 
	The data are means over the years 1969-1971. 
	
Number of cases: 41 


Variable Names: 
City: City 
SO2: Sulfur dioxide content of air in micrograms per cubic meter 
Temp: Average annual temperature in degrees Fahrenheit 
Man: Number of manufacturing enterprises employing 20 or more workers 
Pop: Population size in thousands from the 1970 census 
Wind: Average annual wind speed in miles per hour 
Rain: Average annual precipitation in inches 
RainDays: Average number of days with precipitation per year 
*/

%let path=/folders/myfolders/Linear Models/Project;

* change these to match your computer HDD;
FILENAME REFFILE "&path/projdata3.txt";
libname p1folder "&path";


* Import Data;
PROC IMPORT DATAFILE=REFFILE
	DBMS=DLM
	OUT=p1folder.p1data;
	datarow=2;
	delimiter='09'x;
	GETNAMES=yes;
RUN;



title "Without Transformation";
* prelim checks;

proc contents data=p1folder.p1data;
proc print data=p1folder.p1data;
proc means data=p1folder.p1data q1 median q3 mean clm alpha=0.05;
proc corr data=p1folder.p1data;
proc univariate data=p1folder.p1data;
	hist;
	qqplot;
	id city;
run;

* full model regression with full data and without transformations;
proc reg data=p1folder.p1data
	plots(label)=(CooksD RStudentByLeverage);
	model so2 = Temp Man Pop Wind Rain RainDays / selection=backward;
	id city;
run;
	




/*
Data transformed to normalize
*/

title "Transformed Data";
* consider transforms; 
data p1folder.p1dataTrans;
	set p1folder.p1data;
	logSO2 = log(SO2);
	logMan = log(Man);
	logPop = log(pop);
	logTemp = log(temp);
	RainSq = rain*rain;
	manpercap=man/pop;
	logMpC = log(manpercap);
run;


 
* Transformed data; 

proc corr data=p1folder.p1datatrans;
	var logSo2 logTemp logman logpop Wind RainSq RainDays;
run;

  
proc univariate data=p1folder.p1datatrans normaltest alpha=0.05;
	hist;
	qqplot;
	id city;
	probplot;
run;


proc reg data=p1folder.p1datatrans
	plots(label)=(CooksD RStudentByLeverage);
	model logso2 = logTemp logman logpop Wind RainSq RainDays / selection=backward;
	id city;
	*where city ~="Chicago";
run;





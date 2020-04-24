


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
proc corr data=p1folder.p1data plots=matrix(histogram);

title "Full"; 
proc corr data=p1folder.p1data plots=matrix(histogram nvar=all);
	var  temp Man Pop Wind Rain RainDays;
run;

title "Full without Pop Man"; 
proc corr data=p1folder.p1data plots=matrix(histogram nvar=all);
	var  temp Wind Rain RainDays;
run;

title "High Pop Removed (1000)"; 
proc corr data=p1folder.p1data plots=matrix(histogram nvar=all);
	var  temp Man Pop Wind Rain RainDays;
	where pop < 1000;
	*where man <1000;
run;


title "Arid Climate Removed (rain<=22)"; 
proc corr data=p1folder.p1data plots=matrix(histogram nvar=all);
	var  temp Man Pop Wind Rain RainDays;
	where rain>22 and pop<1200;
	*where man <1000;
run;

*PCA;
proc princomp data=p1folder.p1data ;
	var temp man pop wind rain raindays;
run;



* QQ plots with normality test;
proc univariate normal data=p1folder.p1data noprint;
	qqplot;
	inset probn;
	id city;
run;




* full model regression with full data and without transformations;
title "full model without transformations"; 
proc reg data=p1folder.p1data
	plots(label)=(CooksD RStudentByLeverage);
	model so2 = Temp Man Pop Wind Rain RainDays;
	id city;
	where man < 1600;
run;


* create indicator variable;
data p1folder.p1dataCold;
	set p1folder.p1data;
	cold = 0;
	if temp<58 then cold=1;
	
	manCold = cold*man;
	popCold = cold*pop;
	rainCold = cold*rain;
	rainDCold = raindays*cold;
	windCold = wind*cold;
	
	tInv=1/temp;
run;





proc reg data=p1folder.p1dataCold
	plots(label)=(CooksD RStudentByLeverage);
	model so2 = cold temp mancold man rain raincold
		raindays rainDCold wind windCold 
		/ selection=stepwise sls=0.1 vif collin;
	id city;
	output out=resid residual=r;
run;



proc reg data=p1folder.p1datacold
	plots(label)=(CooksD RStudentByLeverage);
	model so2 = temp mancold raincold windCold
		/ vif collin;
	id city;
	*where city ~= "Providence";
	output out=resid residual=r;
run;


*Residual qq plot;
title "Residuals";
proc univariate data=resid normal noprint;
	qqplot;
	var r;
	inset probn;
run;


proc univariate data=p1folder.p1datacold normal noprint;
	qqplot;
	var manCold raincold temp windcold;
	inset probn;
run;





proc corr data=p1folder.p1datatrans plots=matrix(histogram nvar=all);
	var manCold raincold temp windcold;
run;

proc univariate data=p1folder.p1datacold normal noprint;
	qqplot;
	var manCold raincold temp windcold;
	inset probn;
	id city;
run;
	


proc reg data=p1folder.p1dataCold outest=estimates
		plots(label)=(CooksD RStudentByLeverage);
	model SO2 = manCold raincold temp windcold
		/ spec hcc vif collin dwprob;
	where city ~= "Providence";
	id city;
run;



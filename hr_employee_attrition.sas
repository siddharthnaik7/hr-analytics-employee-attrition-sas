************************************************* TERM PAPER : Employee Attrition (HR Analytics)****************************************************



/**************************************************************************************************************************************************/
/*-------------------------------------------------------- Importing Data-------------------------------------------------------------------------*/
/**************************************************************************************************************************************************/

* Importing data into sas dataset;
proc import datafile = '/home/u43389974/Project/turnover.csv'
 out = work.turnover_raw (rename=(sales=Department)) /*renaming sales column as Department*/
 dbms = CSV
 ;
run;

proc print data = work.turnover_raw(obs=10);
run;

/**************************************************************************************************************************************************/
/*-------------------------------------------------------- Data Summary (Outliers/Missing Values)-------------------------------------------------*/
/**************************************************************************************************************************************************/

* Information about the dataset;
PROC CONTENTS DATA = work.turnover_raw;
title 'Data Summary';
run;

* Checking for outliers and missing values for numerical variables;
PROC MEANS DATA = work.turnover_raw MAXDEC = 0;
TITLE 'Summary of numerical variables of turnover ';
run; 

* based on the results there could be an outlier in average_montly_hours, but based on the data investigation it is found that there is no outlier.;
PROC UNIVARIATE DATA = work.turnover_raw;
   VAR average_montly_hours;
   HISTOGRAM average_montly_hours/NORMAL;
   TITLE 'Checking for outliers in average_montly_hours';
RUN; *data sets with high kurtosis tend to have heavy tails, or outliers. Data sets with low kurtosis tend to have light tails, or lack of outliers.; 

* Checking for missing values for categorical variables.?????????????????????????????????????????????????;
* Checking for missing values for all variables;
proc format;
	value $missfmt ' '='Missing' other='Not Missing';
 	value  missfmt  . ='Missing' other='Not Missing';
run;
 
proc freq DATA=work.turnover_raw; 
	format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
	tables _CHAR_ / missing missprint nocum nopercent;
	format _NUMERIC_ missfmt.;
	tables _NUMERIC_ / missing missprint nocum nopercent;
run;





/**************************************************************************************************************************************************/
/*-------------------------------------------------------- Correlation (Numerical)----------------------------------------------------------------*/
/**************************************************************************************************************************************************/

* Checking for correlations between all numerical variables;
* no severe case of multicollinearity;
PROC CORR DATA = work.turnover_raw PLOTS= MATRIX(NVAR=ALL);
   VAR satisfaction_level last_evaluation number_project average_montly_hours time_spend_company Work_accident promotion_last_5years left;
   TITLE 'Correlations for all numerical variables';
RUN; 
/*                                                 Moderate Positively Correlated Features:

projectCount vs evaluation: 0.349333
projectCount vs averageMonthlyHours: 0.417211
averageMonthlyHours vs evaluation: 0.339742

There is a positive(+) correlation between projectCount, averageMonthlyHours, and evaluation. Which could mean that the employees who spent more 
hours and did more projects were evaluated highly.

												   Moderate Negatively Correlated Feature:

satisfaction vs left: -0.388375

left and satisfaction are highly correlated. I'm assuming that people tend to leave a company more when they are less satisfied.
*/



/**************************************************************************************************************************************************/
/*---------------------------------------------------- Statistical Test for Correlation ----------------------------------------------------------*/
/*--------------------------------------------- One-Sample T-Test (Measuring Satisfaction Level)--------------------------------------------------*/
/**************************************************************************************************************************************************/
/*
Hypothesis Testing: Is there significant difference in the means of satisfaction level between employees who had a turnover and employees who had 
                    no turnover?

Null Hypothesis: (H0: pTS = pES) The null hypothesis would be that there is no difference in satisfaction level between employees who did turnover 
                 and those who did not..

Alternate Hypothesis: (HA: pTS != pES) The alternative hypothesis would be that there is a difference in satisfaction level between employees who 
                       did turnover and those who did not..

*/

PROC TTEST  DATA=work.turnover_raw alpha=0.05;
VAR satisfaction_level;
run;

/*Possibility
PROC TTEST DATA = WORK.turnover_data alpha=0.05;
   class left;
   var satisfaction_level;
RUN;

*/

*RESULT : T-Test = 301.87 | P-Value = <.0001 | Reject Null Hypothesis (95% confidence interval);




/**************************************************************************************************************************************************/
/*------------------------------------- Distribution Plots (Satisfaction - Evaluation - AverageMonthlyHours) -------------------------------------*/
/**************************************************************************************************************************************************/

* employee count VS these 3 variables;
ods graphics off;
proc univariate data=work.turnover_raw NOPRINT;
   label satisfaction_level = 'Satisfaction Level';
   histogram satisfaction_level/ cfill=bigy vscale=count vaxislabel='Employee Count';
   label last_evaluation = 'Employee Evaluation';
   histogram last_evaluation/ cfill=lightskyblue vscale=count vaxislabel='Employee Count';
   label average_montly_hours = 'Average Monthly Hours';
   histogram average_montly_hours/ cfill=coral vscale=count vaxislabel='Employee Count';
run;
ods graphics on;

/*  
	Observation:
	Satisfaction - There is a huge spike for employees with low satisfaction and moderate to high satisfaction.
	Evaluation - There is a bimodal distribution of employees for low evaluations (less than 0.6) and high evaluations (more than 0.8)
	AverageMonthlyHours - There is another bimodal distribution of employees with lower and higher average monthly hours (less than 160 hours & more than 220 hours)
	The evaluation and average monthly hour graphs both share a similar distribution.
	Employees with lower average monthly hours were evaluated less and vice versa.
	If you look back at the correlation matrix, the high correlation between evaluation and averageMonthlyHours does support this finding. */


/**************************************************************************************************************************************************/
/*-------------------------------------------------------- Salary V.S. Turnover ------------------------------------------------------------------*/
/**************************************************************************************************************************************************/


* Employee Salary (low, medium, high) VS turnover (0,1) distribution.;
axis1 label=("Count");
axis3 label=none value=none;
legend1 label=("Left") position=(top right inside) across=2 shape=bar(.12in,.12in) offset=(-1,0);
title1 ls=1 "Employee Salary Fitness Distribution";                                                                                                             
proc gchart data=work.turnover_raw;                                                                                                       
   hbar left/ Discrete TYPE=freq subgroup=left group= salary 
   nostats 
   raxis=axis1
   maxis=axis3
   legend=legend1;                                                                                  
run;

/*
	Summary:

Majority of employees who left either had a low or medium salary.
Barely any employees left with high salary
Employees with low to average salaries tend to leave the company.  */





/**************************************************************************************************************************************************/
/*-------------------------------------------------------- Department VS Turnover ----------------------------------------------------------------*/
/**************************************************************************************************************************************************/

* Count of employees in each department.;
* Departments  vs turnover(0,1);
axis1 label=("Count");
axis2 label=("Department");
axis3 label=none value=none;
legend1 label=("Left") position=(top right inside) across=2 shape=bar(.12in,.12in) offset=(-1,0);
title1 ls=1 "Employee Salary Fitness Distribution";                                                                                                             
proc gchart data=work.turnover_raw;                                                                                                       
   hbar left/ Discrete TYPE=freq subgroup=left group= Department 
   nostats 
   raxis=axis1
   maxis=axis3
   gaxis=axis2
   legend=legend1;                                                                                  
run;

/*
	Summary:

The sales, technical, and support department were the top 3 departments to have employee turnover
The management department had the smallest amount of turnover  */


/**************************************************************************************************************************************************/
/*----------------------------------------------------- Turnover V.S. ProjectCount ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/

* percent vs projectcount  (bars = turnover(0,1));
axis1 label=("Percentage");
axis2 label=("Project Count");
axis3 label=none value=none;
legend1 label=("Left") position=(top right inside) across=2 shape=bar(.12in,.12in) offset=(-1,0);
title1 ls=1 "Turnover V.S. ProjectCount";                                                                                                             
proc gchart data=work.turnover_raw;                                                                                                       
   vbar left/ Discrete TYPE=percent subgroup=left group= number_project 
   nostats 
   raxis=axis1
   maxis=axis3
   gaxis=axis2
   legend=legend1;                                                                                  
run;

/*
	Summary:

More than half of the employees with 2, 6, and 7 projects left the company
Majority of the employees who did not leave the company had 3,4, and 5 projects
All of the employees with 7 projects left the company and also employees with 
3 projects have a minimum employee turnover percentage.
There is an increase in employee turnover rate as project count increases */


/**************************************************************************************************************************************************/
/*----------------------------------------------------- Turnover V.S. Evaluation ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/


*percentage vs Evaluation ---Kernel Density Plot; 
title 'Employee Evaluation Distribution - Turnover V.S. No Turnover';
proc sgplot data=work.turnover_raw; 
  histogram last_evaluation / group=left transparency=0.5;
  density last_evaluation / type=kernel group=left;
  xaxis label="Employee Evaluation";
run;

/*
	Summary:

There is a bimodal distribution for those that had a turnover.
Employees with low performance tend to leave the company more
Employees with high performance tend to leave the company more
The sweet spot for employees that stayed is within 0.6-0.8 evaluation
*/


/**************************************************************************************************************************************************/
/*----------------------------------------------------- Turnover V.S. AverageMonthlyHours ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/


* Kernel Density Estimate Plot;
title 'Employee AverageMonthly Hours Distribution - Turnover V.S. No Turnover';
proc sgplot data=work.turnover_raw; 
  histogram average_montly_hours / group=left transparency=0.5;
  density average_montly_hours / type=kernel group=left;
  xaxis label="Employee Average Monthly Hours";
run;

/*
	Summary:
Another bi-modal distribution for employees that turned over
Employees who had less hours of work (~170 hours or less) left the company more
Employees who had too many hours of work (~230 or more) left the company
Employees who left generally were underworked or overworked.  */


/**************************************************************************************************************************************************/
/*----------------------------------------------------- Turnover V.S. Satisfaction ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/

title 'Employee Satisfaction Distribution - Turnover V.S. No Turnover';
proc sgplot data=work.turnover_raw; 
  histogram satisfaction_level / group=left transparency=0.5;
  density satisfaction_level / type=kernel group=left;
  xaxis label="Employee Satisfaction Level";
run;

/*
	Summary:

There is a tri-modal distribution for employees that turnovered
Employees who had really low satisfaction levels (0.15 or less) left the company more
Employees who had low satisfaction levels (0.3~0.5) left the company more
Employees who had really high satisfaction levels (0.7 or more) left the company more  */


/**************************************************************************************************************************************************/
/*----------------------------------------------------- ProjectCount VS AverageMonthlyHours ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/

title 'Boxplot - ProjectCount V.S. Average Monthly Hours';
proc sgplot data=work.turnover_raw;
	vbox average_montly_hours / category= number_project group=left;
	xaxis label="Project Count";
	yaxis label="Employee Average Monthly Hours";
run;

/*
	Summary:

As project count increased, so did average monthly hours.
Something weird about the boxplot graph is the difference in averageMonthlyHours between people who had a turnover and did not.
Employees who did not have a turnover had consistent averageMonthlyHours, despite the increase in projects
In contrast, employees who did have a turnover had an increase in averageMonthlyHours with the increase in projects  */




/**************************************************************************************************************************************************/
/*----------------------------------------------------- ProjectCount VS Employee Evaluation ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/

title 'Boxplot - ProjectCount V.S. Employee Evaluation';
proc sgplot data=work.turnover_raw;
	vbox last_evaluation / category= number_project group=left;
	xaxis label="Project Count";
	yaxis label="Employee Evaluation";
run;

/*
	Summary:

There is an increase in evaluation for employees who did more projects within the turnover group. 
Again for the non-turnover group, employees here had a consistent evaluation score despite the increase in project counts.
*/


/**************************************************************************************************************************************************/
/*----------------------------------------------------- Satisfaction V.S. Evaluation ---------------------------------------------------------------*/
/**************************************************************************************************************************************************/

PROC sgscatter  DATA = work.turnover_raw;
   PLOT last_evaluation*satisfaction_level 
   / group = left markerattrs=(symbol=CircleFilled size=14) filledoutlinedmarkers ;
   title 'Satisfaction vs Employee Evaluation By Turnover';
   label last_evaluation="Employee Evaluation";
   label satisfaction_level="Satisfaction Level";
RUN;

/*
	Summary:

There are 3 distinct clusters of employees who left the company
Cluster 1 (Hard-working and Sad Employee): Satisfaction was below 0.2 and evaluations were greater than 0.75. 
This could be a good indication that employees who left the company were good workers but felt high demanding with no returns job.

Cluster 2 (Bad and Sad Employee): Satisfaction between about 0.35~0.45 and evaluations below ~0.58. 
This could be seen as employees who were badly evaluated and felt bad at work.

Cluster 3 (Hard-working and Happy Employee): Satisfaction between 0.7~1.0 and evaluations was greater than 0.8. 
Which could mean that employees in this cluster were "ideal". 
They loved their work and were evaluated highly for their performance.

*/


/**************************************************************************************************************************************************/
/*-------------------------------------------------------- Turnover V.S. YearsAtCompany ----------------------------------------------------------------*/
/**************************************************************************************************************************************************/

axis1 label=("Percentage");
axis2 label=("Years At Company");
axis3 label=none value=none;
legend1 label=("Left") position=(top right inside) across=2 shape=bar(.12in,.12in) offset=(-1,0);
title1 ls=1 "Turnover V.S. YearsAtCompany";                                                                                                             
proc gchart data=work.turnover_raw;                                                                                                       
   vbar left/ Discrete TYPE=percent subgroup=left group= time_spend_company
   nostats 
   raxis=axis1
   maxis=axis3
   gaxis=axis2
   legend=legend1;                                                                                  
run;

/*
	Summary:

More than half of the employees with 3, 4 and 5 years left the company
Employees with 5 years should highly be looked into  */

/**************************************************************************************************************************************************/
/*----------------------------------------------------------- Logistic Regression ----------------------------------------------------------------*/
/**************************************************************************************************************************************************/




proc logistic data=work.turnover_raw 
              plots(only)=roc;
 
   class Work_accident (ref='0') / param=ref;
   class promotion_last_5years (ref='0') / param=ref;
   class Department (ref='sales') / param=ref;
   class Salary (ref='low') / param=ref;
   model left(ORDER=FREQ ref='0')=satisfaction_level last_evaluation number_project average_montly_hours time_spend_company Work_accident promotion_last_5years Department Salary 
	/ link=glogit clodds=pl; /*Generalized logit function*/
   effectplot interaction(x=Work_accident) / clm noobs connect;
   effectplot interaction(x=promotion_last_5years) / clm noobs connect;
   effectplot interaction(x=Department) / clm noobs connect;
   effectplot interaction(x=Salary) / clm noobs connect;
   *effectplot interaction(x=Score) / clm noobs connect;
 
   output out=work.logit1 predprobs=i;
   title 'Nominal Logistic Regression Model on HR turnover data';
run;

proc print data=work.logit1 ;
    var ip_: _from_ _into_;
run;


proc freq data=work.logit1;
   tables _from_*_into_;
   title 'Crosstabulation of Observed Responses by Predicted '
         'Responses';
run;



/*
Intepretation of Score
If you were to use these employee values into the equation:

Satisfaction: 0.7
Evaluation: 0.8
YearsAtCompany: 3
You would get:

Employee Turnover Score = (0.7)(-3.769022) + (0.8)(0.207596) + (3)(0.170145) + 0.181896 = 0.14431 = 14%

Result: This employee would have a 14% chance of leaving the company. This information can then be used to form our retention plan.

RETENTION PLAN
*/


/**************************************************************************************************************************************************/
/*----------------------------------------------------------- Clustering (No clear clusters found) ----------------------------------------------------------------*/
/**************************************************************************************************************************************************/



*Creating n-1 dummies;
proc logistic
     data = work.turnover_raw
          noprint
          outdesign = indicators;
     class Salary / param = glm;
     model left =  Salary ;
run;
proc print data = indicators (obs=5);
run;


* Merging the n-1 dummies;
data cluster;
     merge work.turnover_raw
           indicators (drop = Intercept left salarylow);
run;

proc print data = cluster (obs=5);
run;


* Removing unnecessary columns ;
Data cluster;
Set cluster;
Drop left department Salary;
Run;
proc print data = cluster (obs=5);
run;


* Variable Selection;
title;
*%let inputs = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company Work_accident promotion_last_5years DepartmentIT DepartmentRandD Departmentaccou Departmenthr Departmentmanag Departmentmarke Departmentprodu Departmentsuppo Departmenttechn salaryhigh salarymedium ;
%let inputs = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company Work_accident promotion_last_5years salaryhigh salarymedium ;

* to select the non redundant variables;
proc varclus data=cluster maxeigen=0.7 short;
    var &inputs;
run;


* Standardizing;
title;
%let input1 = satisfaction_level average_montly_hours time_spend_company Work_accident promotion_last_5years salaryhigh salarymedium ;
proc stdize data=cluster 
            method=range 
            out=work.scluster 
            outstat=work.stdize;
    var average_montly_hours time_spend_company;
run;
proc print data = scluster (obs=5);
run;

proc sgscatter data=scluster;
    matrix &input1;
run;
*kmeans clustering ;
proc fastclus data=scluster 
              maxclusters=3 
              least=2 
              maxiter=50
              out=work.clusterclus;
    var &input1;
run;

* unstandardizing back;
proc stdize data=work.clusterclus 
            method=in(work.stdize) 
            unstdize 
            out=work.clusterclus;
    var average_montly_hours time_spend_company;
run;

proc sort data=work.clusterclus out=work.sortclus;   *Sorting by Clusters;
    by cluster;
run;

proc surveyselect data=work.sortclus 
                  out=work.sampleclus 
                  method=srs 
                  n=50 
                  seed=123;
    strata cluster;
run;

proc sgscatter data=work.sampleclus;
    matrix &input1 / group=cluster;
run;


* No apparent clusters found;


/**************************************************************************************************************************************************/
/*----------------------------------------------------------- Decision Tree ----------------------------------------------------------------*/
/**************************************************************************************************************************************************/
*Uncomment the code file and rule file lines to get both the files;
ods graphics on;

proc hpsplit data=turnover_raw seed=15531 CVMETHOD=random;
   class left number_project time_spend_company Work_accident promotion_last_5years Department salary;
   model left (event='1') = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company Work_accident promotion_last_5years Department salary;
   grow entropy;
   prune costcomplexity;
   *code file='treecode.sas';
   *rule file='rule.txt';
run;

/*Cost Complexity Curve

PROC HSPLIT selects the parameter value 0 which corresponds to a subtree that has 106 
leaves, because it minimizes the estimate of Average Misclassification Rate, 
which is obtained by 10-fold cross validation.
Breiman’s 1-SE rule chooses the parameter that corresponds to the smallest subtree for 
which the predicted error is less than one standard error above the minimum estimated 
Misclassification Rate (Breiman et al. 1984). This parameter choice (0.0001) corresponds to a tree that has 65 leaves.


*/

ods graphics on;

proc hpsplit data=turnover_raw seed=15531 CVMETHOD=random;
   class left number_project time_spend_company Work_accident promotion_last_5years Department salary;
   model left (event='1') = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company Work_accident promotion_last_5years Department salary;
   grow entropy;
   prune costcomplexity (leaves=65);
   *code file='treecode.sas';
   *rule file='rule.txt';
run;




/*Confusion Matrix*/
/*
			Predicted_No	Predicted_Yes
Actual_No	True_Negetive	False_Positive
Actual_Yes	False_Negetive	True_Positive

			Predicted_No(0)	Predicted_Yes(1)
Actual_No(0)	11377			51
Actual_Yes(1)	190				3381

Our Misclassification Rate is really low
Total Misclassified Records:  241
Misclassification Rate: 1.60%

Total Records Predicted Correctly: 14758
Rate of correct record prediction: 98.39%

False_Negetive value is really low: 160 (Employees have actually left but the model
 Predicted that they haven't left).
False Negetive Error Rate: 1.64%
*/

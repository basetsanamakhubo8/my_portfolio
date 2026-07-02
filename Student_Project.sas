/*PHASE 1*/
/*Create permanent library*/
libname Student "/home/u64443630/Student_Project";

/*Verify Library*/
proc contents data = Student._all_;
run; 

/*Import data*/
proc import datafile = "/home/u64443630/Student_Project/Student_data.csv"
out = Student.data
dbms = csv replace;
getnames = yes;
run; 

/* Inspect the first 100 observations for a layout overview */
proc print data=Student.data (obs=100);
run;

/* Audit numeric missing values */
proc means data=Student.data n nmiss;
    var _numeric_;
run;

/* Audit character variables for blanks or "None" labels */
proc freq data=Student.data;
    tables _character_ / missing;
run;

proc univariate data=Student.data;
    var age Previous_GPA attendance_pct Study_Hours_Per_Day sleep_hours Social_Hours_Week Final_CGPA;
run;


/*PHASE 2*/
/*Data Cleaning and Standardizing*/
data Student.data_clean;
set Student.data;

gender = upcase(substr(gender, 1, 1));
if age < 5 or age > 100 then age = .;


/* Audit categorical variables for Power BI readiness */
proc freq data=Student.data_clean;
    tables gender / nocum nopercent;
run;

/* Audit numeric variables for outliers/missingness */
proc means data=Student.data_clean n nMiss mean min max;
    var _numeric_;
run;


data student_final;
    set student.data_clean;
    
    /* 1. Handling Outliers (Example: Capping GPA at 4.0) */
    if final_cgpa > 4.0 then final_cgpa = 4.0;

    /* 2. Handling Missing Values (Imputation with Mean/Median) */
    if missing(study_hours_per_day) then study_hours_per_day = 15; /* Example: 15 is the median */   
run;


/*PHASE 3*/
proc univariate data=Student.data_clean noprint;
    var Final_CGPA Study_Hours_Per_Day;
    output out=bounds 
           pctlpre=P_G P_S 
           pctlpts=25, 75; 
run;
data student_engineered;

    set Student.data_clean;
   
    if final_cgpa > 4.0 then final_cgpa = 4.0; /* Cap at theoretical max */
   
    length attendance_level $10 performance_cat $8 burnout_alert $3;
    
    /* 1. Performance Category (based on CGPA) */
    if final_cgpa >= 3.5 then performance_cat = 'High';
    else if final_cgpa >= 2.5 then performance_cat = 'Medium';
    else if final_cgpa ^= . then performance_cat = 'Low';

    /* 2. Attendance Level Categories */
    if attendance_pct = 100 then attendance_level = 'Perfect';
    else if attendance_pct >= 85 then attendance_level = 'Good';
    else if attendance_pct >= 70 then attendance_level = 'Moderate';
    else if attendance_pct ^= . then attendance_level = 'Poor';
    
 
    /*Develop at least one productivity-related metric*/
    /* 3. Burnout Flag */
    if sleep_hours < 6 and study_hours_per_day > 6 then burnout_alert = "Yes";
    else burnout_alert = "No";
    
run;
proc means data=student_engineered n nmiss mean min max;
    var Final_CGPA;
run;


title "Academic ROI";
proc corr data=student_engineered pearson;
    var attendance_pct final_cgpa;
run;

title "Average GPA by Attendance Category";
proc means data=student_engineered mean std min max;
    class attendance_level;
    var final_cgpa;
run;



/*PHASE 4*/
/* Export to CSV */
proc export data=Student.data_clean
    outfile="/home/u64443630/Student_Project/Student_Data_Clean.csv"
    dbms=csv
    replace;
run;

/* Export to Excel */
proc export data=Student.data_clean
    outfile="/home/u64443630/Student_Project/Student_Data_Clean.xlsx"
    dbms=xlsx
    replace;
run;

/* Export to CSV */
proc export data=student_engineered
    outfile="/home/u64443630/Student_Project/Student_Engineered_Final.csv"
    dbms=csv
    replace;
run;

/* Export to Excel */
proc export data=student_engineered
    outfile="/home/u64443630/Student_Project/Student_Engineered_Final.xlsx"
    dbms=xlsx
    replace;
run;

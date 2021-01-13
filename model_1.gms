$ontext

MILP Model described by T.Meng, Q.Pan and L.Wang in the paper titled
A distributed permutation flowshop scheduling problem with the
customer order constraint.

$offtext
$onempty
$ontext
Use example for 5 flow shops (factories) and 40 jobs with 5 operations (machines)

$offtext
$ontext
Customer orders an assumption
m 'number of machines' /5/
f 'number of factories' /5/
n 'total number of jobs' /40/
r 'number of customer orders' /50/
$offtext
Scalar
MAX 'Large positive number' /100/
;


* I like to add some letter tags to indicies 
* so it is easier to follow where the number indicies belong

Sets
  i 'machines' /m1*m5/
  j 'job index 1' /j1*j8/
  g 'factories index 1' /f1*f5/
  l 'orders index 1' /o1*o5/  

  
  order2job(l,j)  "mapping of orders to job"

alias(j,k)
alias(g,GG)
alias(l,s)
;  

*Creation of data
Table p(j,i) 'Processing time of job j on machine i'
    m1  m2  m3  m4  m5
j1  1
j2      2
j7              5

;

* this will set the data for all things not assigned to normal, mean=5, std=1
* as it is assumed that the processing times are equal, we will use the following line of code:
p(j,i)$( not p(j,i))=normal(5,1);

* if the previous assumption was not in place we could make it so that higher number machines are slower
* using the following line of code
*p(j,i)$( not p(j,i))=normal(ord(i)*2+5,1);


* We will use the lambda above for creating the order2job mapping
parameter
  lambda(l) /o1 10, o2 5, o3 15, o4 10, o5 10/
  lambda_cumulative(l);

lambda_cumulative(l)=sum(s$(ord(s)<=ord(l)),lambda(s));
order2job(l,j)$(ord(j)>=lambda_cumulative(l-1) and ord(j)<lambda_cumulative(l)) = yes;



*By eching some inputs, we can make sure its parsed properly
display lambda;
display lambda_cumulative;
display p;
display order2job;

Variables
C(i,j) 'Continuous variable denotes completion time of job j on machine i'
X(k,j) 'Binary variable equal to 1 if job j is the immediate successor of job k, and 0 otherwise.'
Y(j,g) 'Binary variable equal to 1 if job j is assigned to factory g, and 0 otherwise'
Cmax
;

Binary variables X, Y;

* I name constrains that are descriptive in some way
* which makes the code a bit more readable, especially during the development and maintenance stages of the constrain definitions 
Equations
ops_factory 'ensures that each job must be assigned to one and only one factory.'
ops_queue 'makes sure the next operation of a job cannot start before its previous operation has been finished.'
pred_1 'state that a job can be processed on a machine only after its immediate predecessor has been completed.'
pred_2 'state that a job can be processed on a machine only after its immediate predecessor has been completed.'
cho_factory 'guarantees that the jobs within the same customer order must be assigned to the same factory'
makespan 'defines the overall makespan among factories'
non_neg 'enforces that the completion time of jobs on machines must be non-negative.'
;

ops_factory(j).. sum(g, Y(j,g)) =e= 1;
ops_queue(i,j).. C(i,j) =g= C(i-1,j) + p(j,i); 

* We will use "big-M" constraints, which are pretty common for easiest way to model binary decisions but lead to weak relaxations

pred_1(i,j,k,g)$(ord(k) < card(k) and ord(j) > ord(k)).. C(i,k) =g= C(i,j) + p(k,i) - MAX*X(k,j) - MAX*(1-Y(k,g)) - MAX*(1-Y(j,g)); 
pred_2(i,j,k,g)$(ord(k) < card(k) and ord(j) > ord(k)).. C(i,j) =g= C(i,k) + p(j,i) - MAX*(1-X(k,j)) - MAX*(1-Y(k,g)) - MAX*(1-Y(j,g)); 
* In order to prevent infeasibility problems, the constrain is set in accordance to the domain of the functions
cho_factory(g,j)$(ord(j)<card(j)).. Y(j,g) =e= Y(j+1,g);

makespan(i,j)$(ord(i)=card(i)).. Cmax =g= C(i,j);
non_neg(i,j).. C(i,j) =g= 0;

* The model includes all the nine constraints
model modelone /all/;

modelone.resLim=3000;

modelone.optfile = 1;

*solving the problem by minimizing Cmax which stands for the total time of competion or makespan
solve modelone using mip minimizing Cmax;


* Echo results
display 'The objective function is';
display C.l,Y.l, Cmax.l;
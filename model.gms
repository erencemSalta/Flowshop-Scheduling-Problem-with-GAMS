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
*Customer orders an assumption
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
  l 'orders index 1' /o1*o4/  
* I adjusted this ^, i think orders are composed of at least 1 job
  
  lambda1(l) 
  lambda2(l)  
  lambda3(l) 
*NOT SURE AT TIME OF ACTUAL NUMBER OF CUSTOMER ORDERS

alias(j,k)
alias(g,GG)
alias(l,s)
;  


Table p(j,i) 'Processing time of job j on machine i'
    m1  m2  m3  m4  m5
j1  1
j2      2
j3
j4
j5
j6
j7
* ..., a bit too much work for dummy data
;
*ACTUAL TIMES NOT CLEAR AT THIS TIME

* Lets do an alternate way to create some dummy data
* this will set the data for all things not assigned to normal, mean=5, std=1
* p(j,i)$( not p(j,i))=normal(5,1);

* or, lets make it so that higher number machines are slower
p(j,i)$( not p(j,i))=normal(ord(i)*2+5,1);


$ontext
Seems like we are missing the mapping of jobs to customer orders
This appears to show up in constraint 6?

this creates that mapping, and then does a simple assign
so that each order has 10 jobs
$offtext
set order2job(l,j)  "mapping of orders to job";
order2job(l,j)$(ord(j)>=(ord(l)-1)*10 and ord(j)<ord(l)*10) = yes;



* Lets echo some inputs to make sure its parsed properly
display p;
display order2job;


Variables
C(i,j) 'Continuous variable denotes completion time of job j on machine i'
X(k,j) 'Binary variable equal to 1 if job j is the immediate successor of job k, and 0 otherwise.'
Y(j,g) 'Binary variable equal to 1 if job j is assigned to factory g, and 0 otherwise'
Cmax
;

Binary variables X, Y;

Equations

Constraint2 'ensures that each job must be assigned to one and only one factory.'
Constraint3 'makes sure the next operation of a job cannot start before its previous operation has been finished.'
Constraint4 'state that a job can be processed on a machine only after its immediate predecessor has been completed.'
Constraint5 'state that a job can be processed on a machine only after its immediate predecessor has been completed.'
Constraint6 'guarantees that the jobs within the same customer order must be assigned to the same factory'
Constraint7 'defines the overall makespan among factories'
Constraint8 'enforces that the completion time of jobs on machines must be non-negative.'
;

Constraint2(j).. sum(g, Y(j,g)) =e= 1;
Constraint3(i,j).. C(i,j) =g= C(i-1,j) + p(j,i); 

* These are called "big-M" constraints, pretty common for easiest way to model binary decisions but lead to weak relaxations
* here is some background on common integer modeling stuf from my professor Jeff Linderoth 
* http://homepages.cae.wisc.edu/~linderot/classes/ie418/lecture1.pdf
* http://homepages.cae.wisc.edu/~linderot/classes/ie418/index.html
Constraint4(i,j,k,g)$(ord(k) < card(k) and ord(j) > ord(k)).. C(i,k) =g= C(i,j) + p(k,i) - MAX*X(k,j) - MAX*(1-Y(k,g)) - MAX*(1-Y(j,g)); 
Constraint5(i,j,k,g)$(ord(k) < card(k) and ord(j) > ord(k)).. C(i,j) =g= C(i,k) + p(j,i) - MAX*(1-X(k,j)) - MAX*(1-Y(k,g)) - MAX*(1-Y(j,g)); 
Constraint6(g,j).. Y(j,g) =e= Y(j+1,g);
Constraint7(i,j)$(ord(i)=card(i)).. Cmax =g= C(i,j);
Constraint8(i,j).. C(i,j) =g= 0;

model modelone /all/;

solve modelone using mip minimizing Cmax;
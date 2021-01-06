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
  j 'job index 1' /j1*j40/
  g 'factories index 1' /f1*f5/
  l 'orders index 1' /o1*o4/  
* I adjusted this ^, i think orders are composed of at least 1 job
  
  order2job(l,j)  "mapping of orders to job"

alias(j,k)
alias(g,GG)
alias(l,s)
;  


Table p(j,i) 'Processing time of job j on machine i'
    m1  m2  m3  m4  m5
j1  1
j2      2
* GAMS mostly works with sparse matricies, so you often can just exclude 0
j7              5
* ..., a bit too much work for dummy data
;
*ACTUAL TIMES NOT CLEAR AT THIS TIME

* Lets do an alternate way to create some dummy data
* this will set the data for all things not assigned to normal, mean=5, std=1
* p(j,i)$( not p(j,i))=normal(5,1);

* or, lets make it so that higher number machines are slower
p(j,i)$( not p(j,i))=normal(ord(i)*2+5,1);


* Lets use the lambda above for creating the order2job mapping
parameter
  lambda(l) /o1 10, o2 5, o3 15, o4 10/
  lambda_cumulative(l);

lambda_cumulative(l)=sum(s$(ord(s)<=ord(l)),lambda(s));
order2job(l,j)$(ord(j)>=lambda_cumulative(l-1) and ord(j)<lambda_cumulative(l)) = yes;



* Lets echo some inputs to make sure its parsed properly
display lambda;
display lambda_cumulative;
display p;
display order2job;

$ontext
When I'm actually building real programs with GAMS, I often will create extra intermediate variables
to make my program more expressive.  Often with GAMS and solvers preprocessing these days, these variables
will all get removed in presolve, so actual efficiency in solving is most often not changed.  And in return
you are able to more easily design new constraints and others can more easily see what your constraints are doing.

As example, in this case I would add a binary variable for whether an order is assigned to a specific factory.  
If an order is assigned to a factory, then you know all jobs in the order to job mapping must also be assigned
to that factory.  These constraints are really easy to write and can be expressive.  And then when you need 
to add the constrain that certain orders can't be processed at certain facilities, that is easy to do since you
already have that intermediate variable
$offtext
Variables
C(i,j) 'Continuous variable denotes completion time of job j on machine i'
X(k,j) 'Binary variable equal to 1 if job j is the immediate successor of job k, and 0 otherwise.'
Y(j,g) 'Binary variable equal to 1 if job j is assigned to factory g, and 0 otherwise'
Cmax
;

Binary variables X, Y;

* One suggestion I have here is that I will often name constrains that are descriptive in some way
* it can make the code a bit more readable, especially when you are down in the constrain definitions 
* and are trying to rememmber what the constraint is for
Equations
Constraint2 'ensures that each job must be assigned to one and only one factory.'
Constraint3 'makes sure the next operation of a job cannot start before its previous operation has been finished.'
*Constraint4 'state that a job can be processed on a machine only after its immediate predecessor has been completed.'
*Constraint5 'state that a job can be processed on a machine only after its immediate predecessor has been completed.'
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
* One of ways to make the relaxations better is to determine what your "MAX" value is, such that the constraint still works and is as tight as possible
* these probably should also be subsetted by order, i.e. only orders need to be processed sequentially?  I cant remember paper but I think that was case
* These are currently causing infeasiblity
*Constraint4(i,j,k,g)$(ord(k) < card(k) and ord(j) > ord(k)).. C(i,k) =g= C(i,j) + p(k,i) - MAX*X(k,j) - MAX*(1-Y(k,g)) - MAX*(1-Y(j,g)); 
*Constraint5(i,j,k,g)$(ord(k) < card(k) and ord(j) > ord(k)).. C(i,j) =g= C(i,k) + p(j,i) - MAX*(1-X(k,j)) - MAX*(1-Y(k,g)) - MAX*(1-Y(j,g)); 

* this needs to be subsetted to just jobs within same order
* this would also be constraint to drop if you wanted orders to be split among multiple factories
* in real world, this would add some addional timing and effort to merge that is not modeled here

* I think constrain as it currently stands will enforce *all* jobs to be processed in a single facility
Constraint6(g,j)$(ord(j)<card(j)).. Y(j,g) =e= Y(j+1,g);
* I wanted to get your problem solving, this constrain was causing infeasibility.  
* It could be from wrapping, i.e. when j index is at cardinality, the constraint will be Y(j,g) =e= (Y(j+1,g)==0, doesn't exist)
* Yup! Ensuring constrain doesn't exist for boundary works.

$ontext
When you come accross an infeasible problem, the best way to debug is by trying to make your problem feasible.
GAMS will sometimes provide some hints in the terminal on which constraints were infeasible.
In this case it pointed out constraint 2, but that was only infeasible because of constraint 6 and above issue.
Sometimes it takes some logic/intuition to figure it out.  
There are also tools, like IIS, which most solvers will implement some form of
$offtext

Constraint7(i,j)$(ord(i)=card(i)).. Cmax =g= C(i,j);
Constraint8(i,j).. C(i,j) =g= 0;

model modelone /all/;

* change time limits
modelone.resLim=3000;

* use solver opt file
* https://www.gams.com/latest/docs/S_CPLEX.html#CPLEXiis
* can use to change solver behavior
modelone.optfile = 1;

solve modelone using mip minimizing Cmax;


* Echo results
display C.l,Y.l;
include "all_different.mzn";
set of int: A;
set of int: B;
array[A] of var B: arr;

var set of B: X;
var set of B: Y;
constraint all_different(arr);
constraint forall (i in index_set(arr)) ( arr[i] in X );
constraint forall (i in index_set(arr)) ( (arr[i] mod 2 = 0) <-> arr[i] in Y );
solve satisfy;
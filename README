This directory contains the lab materials for Compilers.

The following subdirectories exist:

    lab1        Code for Lab 1 -- expressions and statements
    lab2        Code for Lab 2 -- arrays
    lab3        Code for Lab 3 -- procedures
    lab4        Code for Lab 4 -- machine code
    keiko       Keiko bytecode interpreter

## Data Design
### What is bad?
- Redundancy

Theater  | Film | Star | Costar |
------------- | ------------- | ----- | -----  |
Fine Arts   | The Spanish Prisoner |  Pidgeon  |  Martin
Esquire     | L.A. Confidential    | Spacey    | Crowe
Biograph    | L.A. Confidential    | Spacey    | Crowe
Vic         | L.A. Confidential    | Spacey    | Crowe
Village     | The Spanish Prisoner | Pidgeon   | Martin
Water Tower | Ed Wood              | Depp      | Murray

  - Here, the film determines both the star and the costar. So, we're clearly
    storing redundant information, which makes it difficult to do updates. (If
    we want to update the star of L.A. Confidential, for example...)

  - Would be better if we factored this out into:

  ```NowShowing(Theater, Film)```

  ```Starinfo(Film, Star, Costar)```

- Lack of keys
  - If a certain column is a function of some other columns C1 ... C4, C1 ... C4
    should be keys.
  - In the above example, since Film -> Star, Costar, Film should be a key.

### Formalization
- For a certain database instance, two rows agreeing on A -> two rows agreeing
  on B, then A -> B. That is, A determines B.
- FDs can have multiple attributes: A, B -> C, and A, B -> D are legal.
- The above two imply that A, B -> C, D.

- FDs are part of the extended schema, and we'll need to talk to the "customer"
  to determine them, since we often don't have enough info ourselves.

### Reasoning about FDs
- F+ is the closure of the set of FDs, F.
- So, using laws, we can find all FDs, starting from a base set.
- Armstrong's Axioms:
  - Reflexivity: if X ⊆ Y, then Y -> X.
  - Augmentation: if X ⊆ Y, then XA -> YA, for any A.
  - Transativity: if X ⊆ Y, and Y ⊆ Z, X -> Z.
- We can compute the closure just be repeatedly applying these rules, until we
  reach fixpoint.
- This is inefficient, though, since F+ could be exponential in F. So, our
  algorithm would be exponential...
- Instead, we can compute closure with a set of columns, w.r.t. some set of FDs,
  F.
      partialClosure = X;
      while changed
        changed = false
        for each rule R = Y -> a in F, with Y ⊆ partialClosure AND a ∉ partialClosure
          partialClosure += a
          chhanged = true
        end
      end

- This takes time (number of rules in F) * (number of attributes).

### Detecting goodness and badness
- If T has C1, C2, and C3, and C2 is a function of C1 and C3, C1 and C3 better
  be a key of the schema. If not, it's bad! If so, it's good!
- A DB is in BCNF if for (A -> b in F, and b not in A) implies (A -> *) for the
  schema. This means that there is some table in the schema where A is the key.

### Fixing badness
- If a schema is bad, we choose a bad determinant A, then take maximal B s.t. A
  -> B holds in table T.
- Then, divide T into two tables, T1, and T2.
- T1 contains everything in T other than B.
- T2 contains A and B.
- Example:
  - Schema with relation R, attributes ABCD, and dependencies C -> D, C -> A, B
    -> C.
  - First we'll need to list all keys for R. We note that B appears only on the
    LHS, so B must be in every possible key. Looking around, we see that B is
    the only candidate key, since it determines everything else.
  - Now, since it's not in BCNF (because of C), we decmopose. Split R into R1:
    CDA, and R2: BC.
  - Yay! now R1 has C -> *, and R2 has B -> *. So, everything that is a
    determinant is now also a key. (And any superset must also be a key, so we
    can ignore those.)

### Some crap about the completeness of attribute closure

- Who cares?

### BCNF decomposition, and correctness
- Does BCNF decomposition always capture the same information as before
  decomposing?
- Possibly not! For example, if we decompose

- Original relation:

A | B | C |
- | - | - |
1 | 2 | 3
4 | 5 | 6
7 | 2 | 8
1 | 2 | 8
7 | 2 | 3

- Decomposed:

A | B
- | -
1 | 2
4 | 5
7 | 2

B | C
- | -
2 | 3
5 | 6
2 | 8

- Joined again:

A | B | C |
- | - | - |
1 | 2 | 3
4 | 5 | 6
7 | 2 | 8
1 | 2 | 8
7 | 2 | 3

- We've suddenly got more tuples! Could this happen with BCNF decomposition as
  well?

- Other concerns have to do with whether FDs are preserved.
  - Consider R with attributes CSJPD, dependencies JP -> C, and SD -> P.
  - Let's decompose R, starting with SD -> P:
    - T1: SDP, T2: CSJD.
  - Unfortunately, now we've lost the second dependency, since there's no way to
    capture it when J, P, and C are spread across two different tables.

### Information-Preserving (Loseless) decompositions

- A decomposition of R into X and Y is loseless-join w.r.t. a set of FDs F, if,
  for every instance I that satisfies F, πX(I) JOIN  πY(I) = I.
- Fortunately, BNCF decomposition preserves information if applied correctly.
- Proof:
  - If R is a relation with attributes Z = XAU, and we have dependency X -> A,
    we'll split R up into R1: XA, and R2: XU.
  - Let t1 (X,A) be a tuple from R1, and t2 (X, U) be a tuple from R2. Now, t1
    is part of some row t1', and t2 is part of some row t2', where both t1' and
    t2' are in the original relation R.
  - t1 and t2 must agree on X, since they're being joined. Hence, so must t1'
    and t2'. But then t1' and t2' must also agree on A, since X -> A.
  - Finally, we have that t1' = t2', so the two rows are equivalent, and the
    decomposition hasn't introduced any new tuples.

### Dependency-Preserving decompositions
- A decomposition of R into X and Y is dependency preserving if (πX(F) UNION πY(F))+=F+
- Namely, the FDs found in X and Y together are what were found inside R in the
  first place.
- BCNF is not neccessarily dependency-preserving, unfortunately.
  - Consider R with attributes CSJPD, dependencies CS -> J, and J -> D.
  - If we split on CS first, we have CSPD, and CSJ. Then, we've lost the
    information that J -> D, since they're now in two separate tables.
- It can be:
  - Consider R with attributes ABCD, dependencies A -> B, A -> C, D -> A.
  - We just split into DA, and ABC. All dependencies are still here.
- In some cases, BCNF is incapable of producing a dependency-preserving
  decomposition. In some cases, we just need to break in a different order.
- One response to being uanble to produce a dp decomposition is that we should
  use a weaker normal form. 
  - BNCF is 3.5 normal form. 3rd NF allows some redundancy:
    - If A -> B, then A -> * unless b is part of some key
  - Theorem
    - Can always get a dependency-preserving decomposition in 3NF.

- Another response is to just enforce additional constraints on decomposed
  relations, other than key constraints. This is okay, since we generally need
  many of these anyways...

## Multi-value dependencies

Theater | FoodSold | Film |
- | - | - |
1 | Popcorn | Dark Knight
1 | Ice Cream | Lost in Translation
2 | Popcorn | Dark Knight
2 | Ice Cream | Lost in Translation

- This is bad, since the food sold is entirely independent from the film. That is,
  every combination of FoodSold and Film appears. This is a MVD.
- Suppose T has attributes broken into A, B, and C. There is a MVD A ->> B (and
  A -> C) if
    - πAB (T) JOIN πAC (T) equals all of T
- Fourth Normal Form is defined as:
  - For every MVD A ->> B, A is a key.
- If there are violations, split as before.
- By definition, this is loseless, since the initial relation contained every
  combination of the attributes being splitted.

## Armstrong's Axioms for MVDs
- MVD Reflexivity: if X ⊆ Y, then Y -->> X
- MVD Augmentation If X -->> Y, the XZ -->> YZ, for any Z
- MVD Transitivity: If X -->> Y and Y -->> Z, then X -->> Z
- Conversion: If X -> Y then X -->> Y
- Complementation: If X -->> Y, then X -->> (U -Y), where U is the set of all
  attributes
- Interaction If X -->> Y, and XY -> Z, then X -> (Z - Y)

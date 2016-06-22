
# totTime should be in hours
function compareSolversOut(n, totTime)
    
    # first, force a compile
    tab = compareSolversRuns(1000,2)

    tab = compareSolversTime(n, totTime)
    nruns = size(tab,1)-1
    fn = string("compSolvers", n , "x", nruns, ".csv")
    writecsv(fn,tab)

end


compareSolversRuns(n, nruns, maxtime=Inf) = compareSolvers(n, nruns=nruns, maxtime=maxtime)
compareSolversTime(n, totTime) = compareSolvers(n, totTime=totTime)



# totTime comes in hours, convert to seconds
function compareSolvers(n; nruns=10^8, totTime=Inf, maxtime=totTime*60*60/10)

    totTime = totTime*60*60

    akpwBuild = Array(Float64,0)
    akpwSolve = Array(Float64,0)
    primBuild = Array(Float64,0)
    primSolve = Array(Float64,0)
    augBuild = Array(Float64,0)
    augSolve = Array(Float64,0)

    nedges = Array(Int64,0)
    nlist = Array(Int64,0)
    ilist = Array(Int64,0)

    i = 0
    t1 = time()

    while (i < nruns) && (time() <= t1+totTime)
        i = i + 1
        a = wtedChimera(n,i)
        la = lap(a)
        
        b = randn(n)
        b = b - mean(b)

        push!(nlist, n)
        push!(ilist ,i)
        push!(nedges, nnz(a))
        
        tic()
        f = treeSolver(a,akpw)
        t = toq()
        push!(akpwBuild, t)
        
        tic()
        x = f(b, maxtime=maxtime)
        t = toq()
        push!(akpwSolve, t)
        
        tic()
        f = treeSolver(a,prim)
        t = toq()
        push!(primBuild, t)
        
        tic()
        x = f(b, maxtime=maxtime)
        t = toq()
        push!(primSolve, t)
        
        tic()
        f = augTreeLapSolver(la)
        t = toq()
        push!(augBuild, t)
        
        tic()
        x = f(b, maxtime=maxtime)
        t = toq()
        push!(augSolve, t)
        
        print(".")
    end

    tab = ["nlist"; nlist]
    tab = [tab ["ilist"; ilist]]
    tab = [tab ["nedges"; nedges]]
    tab = [tab ["akpwBuild"; akpwBuild]]
    tab = [tab ["akpwSolve"; akpwSolve]]
    tab = [tab ["primBuild"; primBuild]]
    tab = [tab ["primSolve"; primSolve]]
    tab = [tab ["augBuild"; augBuild]]
    tab = [tab ["augSolve"; augSolve]]

    #=
    tab = makeColumn(:nlist)
    tab = [tab makeColumn(:ilist)]
    tab = [tab makeColumn(:nedges)]
    tab = [tab makeColumn(:akpwBuild)]    
    tab = [tab makeColumn(:akpwSolve)]  
    tab = [tab makeColumn(:primBuild)]    
    tab = [tab makeColumn(:primSolve)]  
    tab = [tab makeColumn(:augBuild)]    
    tab = [tab makeColumn(:augSolve)]  
    =#

    return tab
end


function treeSolver(a,treeAlg;maxtime=Inf)
    t = treeAlg(a)
    la = lap(a)
    lt = lap(t)
    f = pcgLapSolver(la,lt;maxtime=maxtime)
end


# try permuting before factorization
# this seems to give a slightly faster solve, although it takes longer to build.
# and, need to figure out how to get the order
function treeSolverp(a,treeAlg=akpw;maxtime=Inf)
    n = size(a,1)
    t = treeAlg(a)
    lt = lap(t)
    ord = Laplacians.bfsOrder(t,1);
    ord = ord[n:-1:1]
    ltord = lt[ord,ord];

    iord = zeros(Int,size(ord));
    iord[ord] = collect(1:n);
    
    fordp = cholfact(ltord)
    laord = la[ord,ord]
    f1 = pcgLapSolver(laord,ltord)    

    fp(b; maxtime=maxtime) = f1(b[ord], maxtime=maxtime)[iord]
end

module Pack.Runner

import Pack.CmdLn.Completion
import Pack.CmdLn.Opts
import Pack.CmdLn.Types
import Pack.Config.Env
import Pack.Config.Types
import public Pack.Core
import Pack.Runner.Database
import Pack.Runner.Develop
import Pack.Runner.Query
import Pack.Runner.Install
import Pack.Runner.New

export covering
runCmd : HasIO io => EitherT PackErr io ()
runCmd = do
  (c,cmd) <- getConfig cmd PrintHelp loglevel
  finally (rmDir $ tmpDir c) $ case cmd of
    Completion a b     => env c >>= complete a b
    CompletionScript f => putStrLn (completionScript f)
    Query m s          => env c >>= query m s
    Fuzzy m s          => idrisEnv c >>= fuzzy m s
    UpdateDB           => updateDB c
    Run (Right p) args => idrisEnv c >>= execApp p args
    Run (Left p)  args => idrisEnv c >>= runIpkg p args
    Repl p             => idrisEnv c >>= idrisRepl p
    Build p            => idrisEnv c >>= build p
    BuildDeps p        => idrisEnv c >>= buildDeps p
    Typecheck p        => idrisEnv c >>= typecheck p
    PrintHelp          => putStrLn usageInfo
    Install ps         => idrisEnv c >>= \e => install e ps
    Remove ps          => idrisEnv c >>= \e => traverse_ (remove e) ps
    PackagePath        => env c >>= putStrLn . packagePathDirs
    LibsPath           => env c >>= putStrLn . packageLibDirs
    DataPath           => env c >>= putStrLn . packageDataDirs
    Info               => env c >>= printInfo
    New dir pty p      => idrisEnv c >>= new dir pty p
    Switch db          => case db == MkDBName "latest" of
      True  => do
        updateDB c
        db  <- defaultColl c.packDir
        env <- idrisEnv ({collection := db} c)
        links env
        writeCollection env
        install env []
      False => idrisEnv ({collection := db} c) >>= links

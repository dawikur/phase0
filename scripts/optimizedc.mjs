import optimizer from "@markw65/monkeyc-optimizer";
import { spawn } from "node:child_process";

const { buildOptimizedProject } = optimizer;
import * as path from "node:path";

const cwd = process.cwd();

const args = process.argv.slice(2);
const parsed = {
  checkBuildPragmas: true,
  checkCompilerLookupRules: "ERROR",
  checkInvalidSymbols: "ERROR",
  checkManifest: true,
  checkTypes: "ERROR",
  compilerWarnings: true,
  enforceStatic: "YES",
  minimizeLocals: true,
  propagateTypes: true,
  skipOptimization: false,
  trustDeclaredTypes: true,
  typeCheckLevel: "Strict",
};

for (let i = 0; i < args.length; i++) {
  const arg = args[i];

  switch (arg) {
    case "--device":
      parsed.device = args[++i];
      break;
    case "--jungles":
      {
        const jungleFiles = args[++i]
          .split(";")
          .map((jungle) => path.resolve(cwd, jungle));
        parsed.jungleFiles = jungleFiles.join(";");
        parsed.workspace = path.dirname(jungleFiles[0]);
      }
      break;
    case "--private-key":
      parsed.developerKeyPath = path.resolve(args[++i]);
      break;
    case "--simulator":
      parsed.simulatorBuild = true;
      break;
    case "--warn":
      parsed.compilerWarnings = true;
      break;
    case "--release":
      parsed.releaseBuild = true;
      break;
    case "--unit-test":
      parsed.testBuild = true;
      break;
    case "--output":
      parsed.program = path.resolve(cwd, args[++i]);
      parsed.buildDir = path.dirname(parsed.program);
      parsed.outputPath = path.join(parsed.buildDir, "optimized");
      break;

    default:
      throw new Error(`Unknown flag: ${arg}`);
      break;
  }
}

try {
  if (!parsed.program) {
    throw new Error("Missing required flag: --output");
  }

  // The optimizer resolves configuration internally and chooses its own output
  // name. Request the command so Makefile's output path also names debug files.
  const result = await buildOptimizedProject(parsed.device ?? null, {
    ...parsed,
    returnCommand: true,
  });
  const outputIndex = result.args.indexOf("-o");
  if (outputIndex < 0 || outputIndex + 1 >= result.args.length) {
    throw new Error("Optimizer returned a compiler command without an output path");
  }
  const compilerArgs = [...result.args];
  compilerArgs[outputIndex + 1] = parsed.program;

  await new Promise((resolve, reject) => {
    const compiler = spawn(result.exe, compilerArgs, {
      cwd: parsed.workspace ?? cwd,
      stdio: "inherit",
    });
    compiler.on("error", reject);
    compiler.on("close", (code, signal) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Compiler failed (${signal ?? code})`));
      }
    });
  });
  console.log("OPTIMIZATION SUCCESSFUL");
} catch (error) {
  console.error(error);
  process.exitCode = 1;
}

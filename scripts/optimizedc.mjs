import { buildOptimizedProject, getConfig } from "@markw65/monkeyc-optimizer";
import { optimizeProgram } from "@markw65/monkeyc-optimizer/sdk-util.js";
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
  extraReferenceTypeChecks: true,
  iterateOptimizer: true,
  iterateOptimizer: true,
  minimizeLocals: true,
  minimizeModules: true,
  postBuildOptimizer: true,
  postBuildPRE: true,
  propagateTypes: true,
  removeArgc: true,
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
    case "--private-key" :
      parsed.developerKeyPath = path.resolve(args[++i]);
      break;
    case "--simulator" :
      parsed.simulatorBuild = true;
      break;
    case "--warn" :
      parsed.compilerWarnings = true;
      break;
    case "--release" :
      parsed.releaseBuild = true;
      break;
    case "--unit-test" :
      parsed.testBuild = true;
      parsed.runTests = true;
      break;
    case "--output":
      parsed.program = args[++i];
      parsed.buildDir = parsed.program.split("/")[0]
      parsed.outputPath = `${parsed.buildDir}/optimized`;
      break;

    default:
      throw new Error(`Unknown flag: ${arg}`);
      break;
  }
}

getConfig({
  ...parsed,
}).then((options) =>
  buildOptimizedProject(parsed.device, options)
    .then((result) =>
      optimizeProgram(
        result.program,
        options.developerKeyPath,
        options.program,
        options
      )
    )
    .then((result) => console.log("OPTIMIZATION SUCCESSFUL"))
);

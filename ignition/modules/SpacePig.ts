import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

const SpacePigModule = buildModule("SpacePigModule", (m) => {

  const spig = m.contract("SpacePig", [], {
    
  });

  return { spig };
});

export default SpacePigModule;

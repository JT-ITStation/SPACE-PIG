import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";



const SpacePigDescendantModule = buildModule("SpacePigDescendantModule", (m) => {


  const spigD = m.contract("SpacePigDescendant", [], {
    
  });

  return { spigD };
});

export default SpacePigDescendantModule;

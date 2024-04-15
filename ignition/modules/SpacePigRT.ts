import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";



const SpacePigRTModule = buildModule("SpacePigRTModule", (m) => {


  const spigRT = m.contract("SpacePigRafleTicket", [], {
    
  });

  return { spigRT };
});

export default SpacePigRTModule;

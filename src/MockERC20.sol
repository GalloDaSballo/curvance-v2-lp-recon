import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor() ERC20("mock", "MOCK") {
    _mint(msg.sender, 1_000_000e18);
  }
}
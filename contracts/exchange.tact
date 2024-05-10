import "@stdlib/deploy";
import "@stdlib/ownable";
import "./tokenSwapWallet.tact";
message WithDraw {
    value: Int;
}
message AddLiquidity {
    amountOfToken: Int;
}
message TONToToken {
    TONValue: Int as coins = ton("1");
}
message TokenToTon {
    tokenValue: Int;
}
message Mint {
    amount: Int;
    receiver: Address;
}

contract Exchange with Deployable {
    tokenAddress: Address;
    num_of_token: Int;
    num_of_TON: Int;
    init(tokenAddress: Address, num_token: Int, num_of_TON: Int){
        self.tokenAddress = tokenAddress;
        self.num_of_token = 0;
        self.num_of_TON = 0;
    }

     fun mint(to: Address, amount: Int) {
        let winit: StateInit = initOf JettonDefaultWallet(myAddress(), sender());
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    queryId: 0,
                    amount: amount,
                    from: myAddress(),
                    forward_ton_amount: 0,
                    forward_payload: emptySlice(),
                    response_destination: myAddress()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    receive(msg: WithDraw){
        send(SendParameters{to: sender(), value: msg.value});
    }

    get fun getReserve(): Int {
        return self.num_of_token;
    }

    get fun getOutputAmountFromSwap(inputAmount: Int, inputReserve: Int, outputReserve: Int): Int {
        require(inputReserve > 0 && outputReserve > 0, "Reserves must be greater than 0");
        let output: Int = inputAmount * outputReserve / (inputReserve + outputReserve);
        return output;
    }

     fun addToken(amount: Int) {
        self.num_of_token += amount;
    }

    receive(msg: TONToToken){
        let reserve_token: Int = self.getReserve();
        let output: Int = self.getOutputAmountFromSwap(msg.TONValue, myBalance(), reserve_token);
        send(SendParameters{to: myAddress(), value: msg.TONValue});
        send(SendParameters{to: sender(), value: output});
    }

    receive(msg: TokenToTon){
        let reserve_token: Int = self.getReserve();
        let output: Int = self.getOutputAmountFromSwap(msg.tokenValue, reserve_token, myBalance());
        send(SendParameters{to: myAddress(), value: msg.tokenValue});
        send(SendParameters{to: sender(), value: output});
        self.addToken(msg.tokenValue);
    }

    receive(msg: AddLiquidity){
        let reserve_token: Int = self.getReserve();
        if (reserve_token <= 0) {
            send(SendParameters{to: sender(), value: msg.amountOfToken});
            self.addToken(msg.amountOfToken);
            self.mint(sender(), msg.amountOfToken);
        } else {
            let amountLPToMint: Int = msg.amountOfToken * reserve_token / myBalance();
            self.mint(sender(), amountLPToMint);
        }
    }
}
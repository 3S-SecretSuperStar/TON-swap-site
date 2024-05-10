import { Blockchain, SandboxContract, TreasuryContract, printTransactionFees } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Example } from '../wrappers/Export';
import '@ton/test-utils';

describe('Escrow', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let example: SandboxContract<Example>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        example = blockchain.openContract(await Example.fromInit());
        deployer = await blockchain.treasury('deployer');

        const deployResult = await example.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: example.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        expect(example.address).toBeTruthy();
        const owner = await example.getOwner();
        expect(owner.toString() === deployer.address.toString()).toBeTruthy();
    });

    it('Test example', async () => {
        const sender = await blockchain.treasury('sender');
        const receiver = await blockchain.treasury('receiver');

        const result = await example.send(
            sender.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );

        expect(result.transactions).toHaveTransaction({
            from: sender.address,
            to: example.address,
            success: true,
        });

        const balance = await example.getTest();
        console.log(toNano(balance));
        expect(toNano(balance)).toBeGreaterThan(toNano('9.9'));
    });
});

import { toNano } from '@ton/core';
import { Example } from '../wrappers/Export';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const example = provider.open(await Example.fromInit());

    await example.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(example.address);
}

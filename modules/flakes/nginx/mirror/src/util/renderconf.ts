import fs from 'fs';

async function main() {
    const dir = await fs.promises.readdir('./conf');
    await fs.promises.mkdir('./lib/conf', { recursive: true });
    for (const file of dir) {
        const content = await fs.promises.readFile(`./conf/${file}`);
        const rendered = content.toString()
                            .replace(/__ROOT_DOMAIN__/g, process.env.ROOT_DOMAIN ?? 'mirror.local.foxden.network')
                            .replace(/__ARCH_MIRROR_ID__/g, process.env.ARCH_MIRROR_ID ?? 'archlinux');
        await fs.promises.writeFile(`./lib/conf/${file}`, rendered);
    }
}

main().catch((e) => {
    throw e;
});

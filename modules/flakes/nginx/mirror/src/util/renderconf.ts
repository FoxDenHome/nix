import fs from 'fs';

async function main() {
    const dir = await fs.promises.readdir('/njs/conf');
    await fs.promises.mkdir('/tmp/ngxconf', { recursive: true });
    for (const file of dir) {
        const content = await fs.promises.readFile(`/njs/conf/${file}`);
        const rendered = content.toString()
                            .replace(/__ROOT_DOMAIN__/g, process.env.ROOT_DOMAIN ?? 'mirror.local.foxden.network')
                            .replace(/__ARCH_MIRROR_ID__/g, process.env.ARCH_MIRROR_ID ?? 'archlinux');
        await fs.promises.writeFile(`/tmp/ngxconf/${file}`, rendered);
    }
}

main().catch((e) => {
    throw e;
});

const { firefox } = require('playwright');

(async () => {
    options = {
        // Path to unzipped files
        executablePath: "/foxhound/build/obj-tf-release/dist/bin/foxhound",
    };

    console.log("Starting browser");
    const browser = await firefox.launch(options);
    console.log("Browser Version:", browser.version(), "connected:", browser.isConnected());
    const context = await browser.newContext();

    // Add hooks to extract taint information
    context.addInitScript(
        { content: "window.addEventListener('__taintreport', (r) => { __playwright_taint_report(r.detail); });"}
    );
    context.exposeBinding("__playwright_taint_report", async function (source, value) {
        console.log(value);
    });

    console.log("Loading new page");
    const page = await context.newPage();

    console.log("Navigating");
    await page.goto("https://example.org/");

    await browser.close();
})();

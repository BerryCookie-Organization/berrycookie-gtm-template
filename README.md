# BerryCookie for Google Tag Manager

Shows the [BerryCookie](https://berrycookie.com) cookie banner and runs Google Consent Mode v2 from Google Tag Manager.

## What it does

On the **Consent Initialization - All Pages** trigger, in this order:

1. Sets the Consent Mode defaults (denied until the visitor decides), one row per region; `security_storage` is always granted.
2. Applies a returning visitor's earlier choice at once, from the first-party `BerryCookieConsent` cookie.
3. Loads the BerryCookie banner script (`bc.js`), which sends the Consent Mode `update` when the visitor decides.

Every decision also pushes `berrycookie_consent_update` to the data layer, for your own triggers.

## Setup

1. Create a free account at [berrycookie.com](https://berrycookie.com/register), add your website and copy its website key (Websites → Install).
2. In Tag Manager: **Templates → Search Gallery → BerryCookie**, add the template.
3. Create a tag from it, paste the website key, choose the default consent per region and fire it on **Consent Initialization - All Pages**.
4. Publish the container and check your site with the free [website check](https://berrycookie.com/en/check-website).

Full guide: [berrycookie.com/en/docs/google-tag-manager](https://berrycookie.com/en/docs/google-tag-manager)

## Without the Gallery

Until the template is listed in the Community Template Gallery, or to pin a version: download [`template.tpl`](template.tpl), then in Tag Manager open **Templates → Tag Templates → New → ⋮ → Import** and save.

## Support

Questions or problems with the template: open an issue in this repository, or write to contact@berrycookie.com.

## License

Apache License 2.0, see [LICENSE](LICENSE).

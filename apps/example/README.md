# Filepond examples

Two tabs:

- **Basic usage** (`lib/basic/basic_usage_page.dart`): the minimal
  integration. A form with an attachments field (files, max 3, upload
  directly) and a send button enabled only when `controller.isSettled`.
  Uploads go to an in-memory server, so it runs without a backend.
- **Upload Lab** (`lib/lab/`): an interactive playground for the package's
  per-file upload status, described below.

```sh
flutter run                                   # in-app fake server, no backend needed
node ../../tool/mock_upload_server.mjs --throttle 256   # optional real HTTP server
```

What you can do:

- **Server scenario**: 200, 201 (`{"filepond": id}`), 500, 422, network error,
  slow, flaky (first attempt fails), mixed (alternating), random.
- **Add sample image / PDF**: generated in memory, so it works on simulators
  and desktop. "Add duplicate" shows the `dublicate` event. The Filepond area
  still opens the real gallery / camera / file picker.
- **Watch**: each file's status, the `operationsStream` log, the controller
  getters (`isSettled`, `isUploading`, `hasFailed`, `allUploaded`), the
  request count, and the Dio interceptor count (must not grow).
- **Act**: upload all, retry failed, remove, and submit. Submit is blocked
  until every file is uploaded.
- **HTTP server mode**: point the lab at the mock server (Android emulator:
  `http://10.0.2.2:3010/upload`). The scenario is sent as `x-scenario`.

`flutter test` runs a smoke test for the basic page and a widget test that
walks through the lab's acceptance flow.

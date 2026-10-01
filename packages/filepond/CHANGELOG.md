## 0.1.0

Per-file upload status. Every `FilepondFile` now carries an explicit status
that the UI and forms can read directly.

### Added
- `FilepondFileStatus { pending, uploading, uploaded, failed }` and the
  `FilepondFile.status` / `FilepondFile.error` fields, plus `isPending`,
  `isUploading`, `isUploaded` and `isFailed` getters. JSON written by older
  versions (no `status`) loads as `uploaded` when `filepond` is set,
  otherwise `pending`.
- `FilepondController.retryUpload(file)` and `retryAllFailed()`.
- Controller getters `hasFailed`, `isUploading`, `isSettled` ("can submit":
  every picked file uploaded; true for an empty list) and `failedFiles`.
- `FilepondController` is now a `ChangeNotifier` and exposes
  `filesListenable`, so widgets can rebuild on status changes without
  subscribing to `operationsStream`.
- `FilepondController.dispose()` cancels in-flight uploads (per-file
  `CancelToken`s). A cancelled upload emits neither `uploaded` nor `failed`.
- `FilepondController.addFile(file)` to add an already-built file (used by
  the pickers; handy for tests and other sources).
- `FilepondFileStatusBar`: progress bar / error + retry, for item builders.
  The default item widgets now show it.
- `allowedExtensions` option for the file picker.

### Changed
- `uploadFile` updates the file in `files` at every step
  (`uploading` → `uploaded` | `failed`), emits the matching operation and
  calls `onFilesChange` each time, including on failure.
- Any 2xx response is a success (201 used to be ignored). Non-2xx responses
  and exceptions mark the file `failed` with the server's message when the
  body has one.
- A JSON object response reads the pond id from `pondLocation` (default
  `filepond`); a plain-string response is used as is.
- The file is looked up again by `id` after the request, so removing a file
  while it uploads no longer writes to the wrong slot or throws `RangeError`.
- `uploadAll()` uploads only `pending` and `failed` files.
- `removeFile` calls `onFilesChange` and matches by `id`.
- Progress resets to 0 when an upload (or retry) starts, and the per-file
  progress stream stays open across retries.
- `uploadDirectly` uploads the newly added file only.
- Duplicate detection (same name or same bytes) now also covers the gallery,
  and the `dublicate` event carries the index of the existing file.

### Fixed
- `FilepondOperation.uploading` emitted an operation of type `remove`.
- Every upload added another `LogInterceptor` to the injected Dio client.
- `attachFile` threw on a cancelled camera or a failed compression.
- `FilepondWidget` re-subscribed to `operationsStream` on every dependency
  change and never cancelled, handling each event several times.

### Deprecated
- `FilepondFile.uploading`: use `status` / `isUploading`. It still mirrors
  `status == uploading`.

## 0.0.2

- Added support for file removal and duplicate detection.
- Added `uploadAll` method to upload all files at once.
- Improved documentation and code comments.
- Added support for listening to file operation events (insert, uploaded, duplicate, remove, failed).
- Added SVG color customization for the file picker UI.
- Improved error handling and state management.
- Added example usage and updated README.

## 0.0.1

- Initial release.
- File picker and uploader components.
- Customizable UI for file selection and upload progress.
- Support for multiple file types (pdf, jpg, png, jpeg).
- Basic controller for file operations.
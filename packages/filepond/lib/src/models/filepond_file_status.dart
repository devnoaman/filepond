/// Upload ("pond") status of a single [FilepondFile].
///
/// | Status      | Meaning                                             |
/// |-------------|-----------------------------------------------------|
/// | [pending]   | Picked, upload not started yet                      |
/// | [uploading] | Upload in flight                                    |
/// | [uploaded]  | Server returned a pond id (`file.filepond != null`) |
/// | [failed]    | Upload threw or the server rejected it              |
enum FilepondFileStatus {
  /// Picked, upload not started yet.
  pending,

  /// Upload request is in flight.
  uploading,

  /// The server accepted the file and returned a pond id.
  uploaded,

  /// The upload threw or the server rejected it. See [FilepondFile.error].
  failed;

  /// Whether a file in this status still blocks a form from being submitted.
  bool get blocksSubmit => this != FilepondFileStatus.uploaded;

  /// Whether a file in this status can be (re)sent by `uploadAll`.
  bool get isUploadable =>
      this == FilepondFileStatus.pending || this == FilepondFileStatus.failed;
}

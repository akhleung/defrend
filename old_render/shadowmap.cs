public static OrthogonalCamera DLShadowCamera(
    PerspectiveCamera pCamera,
    float high,
    float low,
    Vector2 boxSize,
    int texSize,
    Vector3 direction
) {
    // SOURCE: http://www.gamedev.net/community/forums/topic.asp?topic_id=591684
    // CREATE A BOX CENTERED AROUND THE pCAMERA POSITION:
    Vector3 min = pCamera.Position - new Vector3(boxSize.X / 2, 0, boxSize.Y / 2);
    Vector3 max = pCamera.Position + new Vector3(boxSize.X / 2, 0, boxSize.Y / 2);
    min.Y = low;
    max.Y = high;
    BoundingBox boxWS = new BoundingBox(min, max);
    // CREATE A VIEW MATRIX OF THE SHADOW CAMERA
    Vector3 shadowCamPos = pCamera.Position;
    shadowCamPos.Y = high - low;
    Matrix shadowViewMatrix = Matrix.CreateLookAt(shadowCamPos, (shadowCamPos + (direction * 10)), Vector3.Up);
    // TRANSFORM THE BOX INTO LIGHTSPACE COORDINATES:
    Vector3[] cornersWS = boxWS.GetCorners();
    Vector3[] cornersLS = new Vector3[cornersWS.Length];
    Vector3.Transform(cornersWS, ref shadowViewMatrix, cornersLS);
    BoundingBox box = BoundingBox.CreateFromPoints(cornersLS);
    // CREATE PROJECTION MATRIX
    Matrix shadowProjMatrix = Matrix.CreateOrthographicOffCenter(box.Min.X, box.Max.X, box.Min.Y, box.Max.Y, -box.Max.Z, -box.Min.Z);
    Matrix shadowViewProjMatrix = shadowViewMatrix * shadowProjMatrix;
    Vector3 shadowOrigin = Vector3.Transform(Vector3.Zero, shadowViewProjMatrix);
    shadowOrigin *= (texSize / 2.0f);
    Vector2 roundedOrigin = new Vector2((float)Math.Round(shadowOrigin.X), (float)Math.Round(shadowOrigin.Y));
    Vector2 rounding = roundedOrigin - new Vector2(shadowOrigin.X, shadowOrigin.Y);
    rounding /= (texSize / 2.0f);
    Matrix roundMatrix = Matrix.CreateTranslation(new Vector3(rounding.X, rounding.Y, 0.0f));
    shadowViewProjMatrix *= roundMatrix;
    return new OrthogonalCamera(shadowCamPos, shadowViewProjMatrix);
}

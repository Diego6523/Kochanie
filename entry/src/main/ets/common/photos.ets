// Bundled demo photos. $r() needs literal resource names, so map names explicitly.
export const DEMO_PHOTOS: string[] = ['demo_photo_1', 'demo_photo_2', 'demo_photo_3'];

export function photoResource(name: string | undefined): Resource {
  if (name === 'demo_photo_2') {
    return $r('app.media.demo_photo_2');
  }
  if (name === 'demo_photo_3') {
    return $r('app.media.demo_photo_3');
  }
  return $r('app.media.demo_photo_1');
}

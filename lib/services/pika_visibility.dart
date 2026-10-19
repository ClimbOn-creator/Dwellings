/// Pika belongs to individual workspaces and their working tools, never public marketing pages.
bool pikaAllowedOnPage(String page) {
  if (page == 'member/overview') return false;
  return page.startsWith('buyer/') ||
      page.startsWith('seller/') ||
      page.startsWith('member/') ||
      page.startsWith('room/') ||
      page.startsWith('learning-') ||
      page.startsWith('learning/') ||
      const {
        'comparison',
        'resources',
        'resource-provider',
        'transaction-rooms',
        'document-guides',
        'blueprint',
        'readiness',
      }.contains(page);
}

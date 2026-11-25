/// Pika is available in Buyer, Seller and Member tools. Learning opts out.
bool pikaAllowedOnPage(String page) {
  if (page.startsWith('learning-') ||
      page.startsWith('learning/') ||
      page == 'member/overview' ||
      page == 'comparison')
    return false;
  return page.startsWith('buyer/') ||
      page.startsWith('seller/') ||
      page.startsWith('member/') ||
      page.startsWith('room/') ||
      const {
        'resources',
        'resource-provider',
        'transaction-rooms',
        'document-guides',
        'blueprint',
        'readiness',
      }.contains(page);
}

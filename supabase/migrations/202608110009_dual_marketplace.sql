alter table public.provider_profiles
  drop constraint if exists provider_profiles_provider_type_check;
alter table public.provider_profiles
  add constraint provider_profiles_provider_type_check check (
    provider_type in (
      'realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender',
      'business_broker', 'ma_lawyer', 'quality_of_earnings',
      'commercial_lender', 'tax_advisor', 'insurance_advisor',
      'human_resources', 'cybersecurity', 'industry_advisor', 'wealth_manager'
    )
  );

alter table public.sponsored_placements
  drop constraint if exists sponsored_placements_provider_type_check;
alter table public.sponsored_placements
  add constraint sponsored_placements_provider_type_check check (
    provider_type in (
      'realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender',
      'business_broker', 'ma_lawyer', 'quality_of_earnings',
      'commercial_lender', 'tax_advisor', 'insurance_advisor',
      'human_resources', 'cybersecurity', 'industry_advisor', 'wealth_manager'
    )
  );

alter table public.profiles
  drop constraint if exists profiles_account_role_check;
alter table public.profiles
  add constraint profiles_account_role_check check (
    account_role in (
      'user', 'realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender',
      'business_broker', 'ma_lawyer', 'quality_of_earnings',
      'commercial_lender', 'tax_advisor', 'insurance_advisor',
      'human_resources', 'cybersecurity', 'industry_advisor', 'wealth_manager'
    )
  );

alter table public.membership_applications
  drop constraint if exists membership_applications_applicant_type_check;
alter table public.membership_applications
  add constraint membership_applications_applicant_type_check check (
    applicant_type in (
      'homebuyer', 'investor', 'business_buyer', 'realtor', 'mortgage_broker', 'lawyer',
      'accountant', 'lender', 'business_broker', 'ma_lawyer',
      'quality_of_earnings', 'commercial_lender', 'tax_advisor',
      'insurance_advisor', 'human_resources', 'cybersecurity',
      'industry_advisor', 'wealth_manager'
    )
  );

insert into public.provider_profiles (
  id, provider_type, display_name, company_name, job_title, description,
  years_experience, review_score, review_count, verified, is_example,
  photo_index
) values
  ('20000000-0000-4000-8000-000000000001', 'business_broker', 'Amelia Foster', 'Northstar Business Sales', 'Business Broker', 'Business search, valuation guidance, confidential marketing and buyer negotiation.', 14, 4.9, 82, false, true, 0),
  ('20000000-0000-4000-8000-000000000002', 'business_broker', 'Liam Desai', 'Pacific Transaction Partners', 'Business Broker', 'Lower-middle-market acquisitions, seller outreach and transaction coordination.', 11, 4.8, 67, false, true, 1),
  ('20000000-0000-4000-8000-000000000003', 'ma_lawyer', 'Nadia Campbell', 'Campbell M&A Law', 'M&A Lawyer', 'Letters of intent, corporate diligence, purchase agreements and closing conditions.', 16, 4.9, 74, false, true, 2),
  ('20000000-0000-4000-8000-000000000004', 'ma_lawyer', 'Julian Park', 'Harbour Corporate Legal', 'Corporate Transactions Lawyer', 'Share and asset purchases, representations, indemnities and transition agreements.', 13, 4.8, 61, false, true, 3),
  ('20000000-0000-4000-8000-000000000005', 'quality_of_earnings', 'Grace Okafor', 'ClearLedger Advisory', 'Quality of Earnings Director', 'Earnings normalization, working-capital analysis and financial diligence.', 15, 4.9, 89, false, true, 4),
  ('20000000-0000-4000-8000-000000000006', 'quality_of_earnings', 'Thomas Leung', 'Northline Transaction Services', 'Transaction Advisory CPA', 'Cash proof, add-back testing, customer concentration and closing balance sheets.', 12, 4.8, 72, false, true, 5),
  ('20000000-0000-4000-8000-000000000007', 'commercial_lender', 'Mia Reynolds', 'Western Commercial Bank', 'Acquisition Finance Director', 'Cash-flow lending, acquisition debt and working-capital facilities.', 14, 4.8, 58, false, true, 6),
  ('20000000-0000-4000-8000-000000000008', 'commercial_lender', 'Arjun Mehta', 'Growth Capital Credit', 'Commercial Lending Partner', 'Sponsor-backed and owner-operated business acquisition financing.', 11, 4.7, 49, false, true, 7),
  ('20000000-0000-4000-8000-000000000009', 'tax_advisor', 'Sophie Tremblay', 'Continuity Tax Partners', 'Transaction Tax Adviser', 'Asset-versus-share structure, tax diligence and post-close planning.', 17, 4.9, 77, false, true, 8),
  ('20000000-0000-4000-8000-000000000010', 'tax_advisor', 'Marcus Chen', 'Keystone Tax Advisory', 'Corporate Tax CPA', 'Purchase-price allocation, reorganizations and owner-manager tax strategy.', 13, 4.8, 66, false, true, 9),
  ('20000000-0000-4000-8000-000000000011', 'insurance_advisor', 'Olivia Brooks', 'Shieldline Risk', 'Commercial Insurance Adviser', 'Liability, property, key-person and transaction-risk coverage.', 12, 4.8, 54, false, true, 0),
  ('20000000-0000-4000-8000-000000000012', 'insurance_advisor', 'Ethan Clarke', 'Continuum Insurance', 'Business Risk Adviser', 'Coverage diligence, claims history and post-close insurance programs.', 10, 4.7, 43, false, true, 1),
  ('20000000-0000-4000-8000-000000000013', 'human_resources', 'Aisha Morgan', 'PeopleBridge HR', 'HR Due Diligence Lead', 'Employment obligations, compensation, retention and transition planning.', 14, 4.9, 69, false, true, 2),
  ('20000000-0000-4000-8000-000000000014', 'human_resources', 'Lucas Nguyen', 'Transition Workforce Advisory', 'People Integration Adviser', 'Organizational risk, management continuity and first-100-day planning.', 11, 4.8, 57, false, true, 3),
  ('20000000-0000-4000-8000-000000000015', 'cybersecurity', 'Isabelle Roy', 'SignalFort Security', 'Cyber Due Diligence Principal', 'Cybersecurity, privacy, access control and technology-risk assessment.', 13, 4.9, 71, false, true, 4),
  ('20000000-0000-4000-8000-000000000016', 'cybersecurity', 'Mateo Wilson', 'Northwall Cyber', 'Security Assessment Lead', 'Infrastructure, incident history, vendor risk and remediation planning.', 10, 4.8, 52, false, true, 5),
  ('20000000-0000-4000-8000-000000000017', 'industry_advisor', 'Chloe Bennett', 'SectorWorks Advisory', 'Industry Adviser', 'Sector benchmarks, commercial diligence and competitive positioning.', 18, 4.9, 84, false, true, 6),
  ('20000000-0000-4000-8000-000000000018', 'industry_advisor', 'Benjamin Singh', 'Operator Insight Group', 'Operating Adviser', 'Operational benchmarking, owner transition and growth-plan validation.', 16, 4.8, 73, false, true, 7),
  ('20000000-0000-4000-8000-000000000019', 'wealth_manager', 'Emma Laurent', 'Longview Private Wealth', 'Private Wealth Adviser', 'Buyer liquidity, concentration risk and post-close wealth planning.', 15, 4.9, 91, false, true, 8),
  ('20000000-0000-4000-8000-000000000020', 'wealth_manager', 'Nathan Patel', 'Continuity Wealth Partners', 'Business Owner Wealth Adviser', 'Acquisition funding strategy, reserves and long-term owner planning.', 12, 4.8, 64, false, true, 9)
on conflict (id) do update set
  provider_type = excluded.provider_type,
  display_name = excluded.display_name,
  company_name = excluded.company_name,
  job_title = excluded.job_title,
  description = excluded.description,
  years_experience = excluded.years_experience,
  review_score = excluded.review_score,
  review_count = excluded.review_count,
  is_example = true,
  photo_index = excluded.photo_index;

comment on table public.provider_profiles is
  'Dual marketplace directory for PropertyIQ and DealIQ specialists. Example profiles are fictional and cannot receive live introductions.';

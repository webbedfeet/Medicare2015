#' ---
#' title: Understanding the data design and simulation
#' author: Abhijit
#' date: February 27, 2019
#' output:
#'   html_document:
#'     toc: true
#'     #toc_float: true
#'     theme: journal
#'     highlight: zenburn
#'     md_extensions: +definition_lists
#' ---
#' 
#' # The conceptual model
#' 
#' The underlying conceptual model that Mike proposes is
#' 
#' ```
#' rate = [patient characteristics] + [physician characteristics] + [behavioral characteristics] + error
#' ```
#' 
#' There are several things that are believed to contribute to the chance of getting
#' a knee transplant. First, let's consider some biology:
#' 
#' 1. Severity of knee condition
#'   ~ This would look at the number of knee-related visits, using `koa_visits`, 
#'     `kneesymptom_visits` or `allkneevisits`. These might vary by year as the 
#'     knee conditions progress or improve. This might also be normalized with 
#'     time of follow-up to get an overall sense of severity. 
#' 
#' 1. Demographics
#'   ~ Older people, or people of a certain race, may be differentially prone to get
#'   a transplant. This effect may be confounded by socio-economic status, rural/urban
#'   divide, or if they are poor.
#'   
#' 1. Comorbidities
#'   ~ We might like to create a comorbidity score as the number of comorbidities
#'   present, with the idea that more morbid patients might be less likely to
#'   receive transplants. There may be an issue with recency of the comorbidity:
#'   `acutemi`, `afib`, `ckd`, `depress`,`diab`,`ulcers` are all measuring recent
#'   incidence, while the others reflect a history (ever happened). `hiv` might
#'   just be an issue anytime because of surgery, as will `stroke` and `liver`.
#'   Comorbidities (or hypochondria) severity might be indicated by `op_visits`,
#'   the number of outpatient visits the patient made. Obesity (`obese_wtperc`) is
#'   only available as an aggregate percentage in the HRR, so might be of limited
#'   value. It may also influence local physician/patient behavior, if one sees
#'   more obese patients or a relatively healthier population.
#' 
#' 1. Proximity to death
#'   ~ If someone is about to die, they are more unlikely to get a transplant. This 
#'   can be quantified as odds of getting a transplant if patient died that year, 
#'   or the following year.
#'   
#' 1. Previous transplant
#'   ~ Having one knee replacement should increase the risk that you get the other 
#'   knee replaced. 
#' 
#' Next, we'll look at physician/local characteristics that can influence the rate:
#' 
#' 1. Local characteristics
#'   ~ 
#' 
#' The part we're interested here is in the physician characteristics, with the
#' behavioral characteristics being nuisance, in some sense. 
#' 
#' # Data description
#' 
#' The physician characteristics are obtained as aggregate ecological measures like
#' 
#' - Percentage with Medicare Advantage (`Mcare_adv_wtperc`)
#' - Density of orthopedic surgeions (`Ortho_per_100000`)
#' 
#' There are also some ecological measures for patient characteristics:
#' 
#' - % obesity (`obese_wtperc`)
#' - % with physical occupation (`physjob__wtperc`)
#' - % smokers (`smoking_wtperc`)
#' 
#' At the patient level we have
#' 
#' - Age (continuous, `age_at_end_ref_yr`, discrete, `agecat`)
#' - Gender (`Male`, 1=male, 0=female)
#' - Race (`Race`, categorized as 1=white, 2=black, 3=hispanic, 4=asian, 5=other)
#' - A listing of 20 comorbidities, as 0/1 variables
#' - knee OA visits (continuous, `koa_visits`, discrete, `koa`, 0/1)
#' - knee symptom visits (continous, `kneesymptom_visits`, discrete, `kneesymptoms`, 0/1)
#' - Total knee visits (continuous, `allkneevisits`, discrete, `knee_patient`, 0/1)
#' - Dead or alive (`dead`, 1 = dead in year)
#' - Time of followup during calendar year (`personyrs`, 0-1 yrs)
#' - Current year of observation (`bene_enrollmt_ref_yr`, 2011-2015)
#' - Poor or on Medicaid (`poor`, 0/1)
#' 
#' We also have two variables that are based on ZCTA's, rather than the actual 
#' HRR's
#' 
#' - Socio-economic status (`zscore`)
#' - Rural district (`rural`, 0/1)
#' 

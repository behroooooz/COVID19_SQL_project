/*

Cleaning Data in SQL Queries

*/

Select *
From PortfolioProject..NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDate, SaleDateCleaned
From PortfolioProject..NashvilleHousing;

--Update PortfolioProject.dbo.NashvilleHousing
--SET SaleDate = CAST(SaleDate as Date)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateCleaned Date;

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDateCleaned = CAST(SaleDate as Date);


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select ParcelID, PropertyAddress
From PortfolioProject..NashvilleHousing
--where PropertyAddress is NULL
Order by ParcelID;


Select N1.ParcelID, N1.PropertyAddress, N2.ParcelID, N2.PropertyAddress
From PortfolioProject..NashvilleHousing N1
JOIN PortfolioProject..NashvilleHousing N2
		ON N1.ParcelID = N2.ParcelID
Where N1.[UniqueID ] != N2.[UniqueID ]
And N1.PropertyAddress is Null;

-- Using ParcelID we can fill in the NULL values in PropertyAddress.

Update N1
SET PropertyAddress = ISNULL(N1.PropertyAddress, N2.PropertyAddress)
From PortfolioProject..NashvilleHousing N1
JOIN PortfolioProject..NashvilleHousing N2
		ON N1.ParcelID = N2.ParcelID
Where N1.[UniqueID ] != N2.[UniqueID ]


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


--  PropertyAddress


Select PropertyAddress, 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) As PropertyStreetAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) As ProertyCityAddress
From PortfolioProject..NashvilleHousing;

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertyStreetAddress VARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);


ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertyCityAddress VARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertyCityAddress = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));


--  OwnerAddress:

Select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) As OwnerStreetAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) As OwnerCityAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) As OwnerStateAddress
From PortfolioProject..NashvilleHousing
Order By 1 desc


ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerStreetAddress VARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);


ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerCityAddress VARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerCityAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);
 
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerStateAddress VARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerStateAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

Select SoldAsVacant, COUNT(SoldAsVacant) 
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2;

--Select SoldAsVacant,
--		Case When SoldAsVacant='Y' Then 'Yes'
--			 When SoldAsVacant='N' Then 'No'
--			 Else SoldAsVacant
--		End
--From PortfolioProject..NashvilleHousing;

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = Case When SoldAsVacant='Y' Then 'Yes'
						When SoldAsVacant='N' Then 'No'
						Else SoldAsVacant
				   End;


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
Select count(*) As CountOfRows
From PortfolioProject..NashvilleHousing;

With RowNumCTE as 
(
	Select *, 
	ROW_NUMBER() OVER 
		(PARTITION BY ParcelID,
					  PropertyAddress,
					  SaleDate,
					  SalePrice,
					  LegalReference
			Order BY
					  UniqueID) row_num
	From PortfolioProject..NashvilleHousing
	--Order BY row_num desc
)
DELETE 
From RowNumCTE
Where row_num > 1;



Select count(*) As CountOfRows
From PortfolioProject..NashvilleHousing;


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress, TaxDistrict


